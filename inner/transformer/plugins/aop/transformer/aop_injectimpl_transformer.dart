// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'aop_iteminfo.dart';
import 'aop_tranform_utils.dart';

class AopStatementsInsertInfo {
  AopStatementsInsertInfo(
      {required this.library,
      this.source,
      this.constructor,
      this.procedure,
      this.node,
      this.aopItemInfo,
      this.aopInsertStatements});

  final Library library;
  final Source? source;
  final Constructor? constructor;
  final Procedure? procedure;
  final Node? node;
  final AopItemInfo? aopItemInfo;
  final List<Statement>? aopInsertStatements;
}

class AopInjectImplTransformer extends Transformer {
  AopInjectImplTransformer(
      this._aopItemInfoList, this._libraryMap, this._uriToSource);

  late final List<AopItemInfo> _aopItemInfoList;
  late final Map<String, Library> _libraryMap;
  late final Map<Uri, Source> _uriToSource;
  final Set<VariableDeclaration> _mockedVariableDeclaration =
      <VariableDeclaration>{};
  final Map<String, VariableDeclaration> _originalVariableDeclaration =
      <String, VariableDeclaration>{};
  late Class _curClass;
  late Node _curMethodNode;
  Library? _curAopLibrary;
  AopStatementsInsertInfo? _curAopStatementsInsertInfo;

  @override
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) {
    node.transformChildren(this);
    _originalVariableDeclaration.putIfAbsent(node.name!, () => node);
    return node;
  }

  @override
  VariableGet visitVariableGet(VariableGet node) {
    node.transformChildren(this);
    if (_mockedVariableDeclaration.contains(node.variable)) {
      final VariableGet variableGet =
          VariableGet(_originalVariableDeclaration[node.variable.name]!);
      return variableGet;
    }
    return node;
  }

  @override
  InstanceGet visitInstanceGet(InstanceGet node) {
    node.transformChildren(this);

    final Reference reference = node.interfaceTargetReference;

    if (reference == null) {
      return node;
    }

    final Node interfaceTargetNode = node.interfaceTargetReference.node!;
    if (_curAopLibrary != null) {
      if (interfaceTargetNode is Field) {
        if (interfaceTargetNode.fileUri == _curAopLibrary!.fileUri) {
          final List<String> keypaths =
              AopUtils.getPropertyKeyPaths(node.toString());
          final String firstEle = keypaths[0];
          if (node.receiver is ThisExpression) {
            final Class cls = _curClass;
            final Field field =
                AopUtils.findFieldForClassWithName(cls, node.name.text)!;

            final ThisExpression thisE = ThisExpression();

            final InstanceGet instanceGet = InstanceGet(
                InstanceAccessKind.Instance,
                thisE,
                Name(field.name.text, _curClass.parent as Library),
                interfaceTarget: field,
                resultType: field.type);

            return instanceGet;
          } else {
            final VariableDeclaration? variableDeclaration =
                _originalVariableDeclaration[firstEle];

            if (variableDeclaration == null) {
              return node;
            }
            if (variableDeclaration.type is InterfaceType) {
              final Class cls = _curClass;
              final Field field =
                  AopUtils.findFieldForClassWithName(cls, node.name.text)!;
              InstanceGet instanceGet = InstanceGet(
                  InstanceAccessKind.Instance, node.receiver, field.name,
                  interfaceTarget: node.interfaceTarget,
                  resultType: node.resultType);
              return instanceGet;
            }
          }
        }
      }
    }
    return node;
  }

  @override
  FunctionExpression visitFunctionExpression(FunctionExpression node) {
    node.transformChildren(this);
    checkIfInsertInFunction(node.function);
    return node;
  }

  @override
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) {
    node.transformChildren(this);
    checkIfInsertInFunction(node.function);
    return node;
  }

  @override
  InstanceSet visitInstanceSet(InstanceSet node) {
    node.transformChildren(this);

    if (!(node.receiver is ThisExpression)) {
      return node;
    }

    final String text = node.name.text;
    if (text != null) {
      late Field exchangeField;
      for (Field field in _curClass.fields) {
        if (field.name.text == text) {
          exchangeField = field;
          break;
        }
      }

      if (exchangeField != null) {
        final ThisExpression thisE = ThisExpression();

        final InstanceGet property = InstanceGet(InstanceAccessKind.Instance,
            thisE, Name(exchangeField.name.text, _curClass!.parent as Library),
            interfaceTarget: exchangeField, resultType: exchangeField.type);

        InstanceSet newSet = InstanceSet(
            node.kind, thisE, exchangeField.name, node.value,
            interfaceTarget: exchangeField);
        return newSet;
      }
    }

    return node;
  }

  @override
  FunctionNode visitFunctionNode(FunctionNode node) {
    node.transformChildren(this);
    checkIfInsertInFunction(node);
    return node;
  }

  @override
  Block visitBlock(Block node) {
    node.transformChildren(this);
    if (_curAopStatementsInsertInfo != null) {
      final Library library = _curAopStatementsInsertInfo!.library;
      final Source source = _curAopStatementsInsertInfo!.source!;
      final AopItemInfo aopItemInfo = _curAopStatementsInsertInfo!.aopItemInfo!;
      final List<Statement> aopInsertStatements =
          _curAopStatementsInsertInfo!.aopInsertStatements!;
      insertStatementsToBody(
          library, source, node, aopItemInfo, aopInsertStatements);
    }
    return node;
  }

  void aopTransform() {
    //Inject from the beginning of the file to the end
    sortTransform();

    //Merge aop items that inject in the same line.
    mergeTransform();

    for (AopItemInfo aopItemInfo in _aopItemInfoList) {
      final Library aopAnnoLibrary = _libraryMap[aopItemInfo.importUri]!;
      final String clsName = aopItemInfo.clsName;
      if (aopAnnoLibrary == null) {
        return;
      }
      //类静态/实例方法
      if ((clsName?.length ?? 0) > 0) {
        Class expectedCls;
        for (Class cls in aopAnnoLibrary.classes) {
          if (cls.name == aopItemInfo.clsName) {
            expectedCls = cls;
            //Check Constructors
            if (aopItemInfo.methodName == aopItemInfo.clsName ||
                aopItemInfo.methodName!.startsWith(aopItemInfo.clsName + '.')) {
              for (Constructor constructor in cls.constructors) {
                if (cls.name +
                            (constructor.name.text == ''
                                ? ''
                                : '.' + constructor.name.text) ==
                        aopItemInfo.methodName &&
                    true == aopItemInfo.isStatic) {
                  _curClass = expectedCls;
                  transformConstructor(
                      aopAnnoLibrary,
                      _uriToSource[aopAnnoLibrary.fileUri]!,
                      constructor,
                      aopItemInfo);
//                  return;
                }
              }
            }
            //Check Procedures
            for (Procedure procedure in cls.procedures) {
              if (procedure.name.text == aopItemInfo.methodName &&
                  procedure.isStatic == aopItemInfo.isStatic) {
                _curClass = expectedCls;
                transformMethodProcedure(
                    aopAnnoLibrary,
                    _uriToSource[aopAnnoLibrary.fileUri]!,
                    procedure,
                    aopItemInfo);
//                return;
              }
            }
            break;
          }
        }
        _libraryMap.forEach((String importUri, Library lib) {
          for (Class cls in lib.classes) {
            if (cls.name == aopItemInfo.clsName) {
              for (Procedure procedure in cls.procedures) {
                if (procedure.name.text == aopItemInfo.methodName &&
                    procedure.isStatic == aopItemInfo.isStatic) {
                  _curClass = cls;
                  transformMethodProcedure(
                      lib,
                      _uriToSource[aopAnnoLibrary.fileUri]!,
                      procedure,
                      aopItemInfo);
                }
              }
            }
          }
        });
      } else {
        for (Procedure procedure in aopAnnoLibrary.procedures) {
          if (procedure.name.text == aopItemInfo.methodName &&
              procedure.isStatic == aopItemInfo.isStatic) {
            transformMethodProcedure(aopAnnoLibrary,
                _uriToSource[aopAnnoLibrary.fileUri]!, procedure, aopItemInfo);
          }
        }
      }
    }
  }

  void transformMethodProcedure(Library library, Source source,
      Procedure procedure, AopItemInfo aopItemInfo) {
    final List<Statement> aopInsertStatements =
        onPrepareTransform(library, procedure, aopItemInfo);
    if (procedure.function.body is Block && aopInsertStatements.isNotEmpty) {
      _curMethodNode = procedure;
      insertStatementsToBody(library, source, procedure.function, aopItemInfo,
          aopInsertStatements);
    }
    onPostTransform(aopItemInfo);
  }

  void transformConstructor(Library library, Source source,
      Constructor constructor, AopItemInfo aopItemInfo) {
    final List<Statement> aopInsertStatements =
        onPrepareTransform(library, constructor, aopItemInfo);

    final Statement body = constructor.function.body!;
    bool canBeInitializers = true;
    for (Statement statement in aopInsertStatements) {
      if (!(statement is AssertStatement)) {
        canBeInitializers = false;
      }
    }
    //Insert in body part
    if (!canBeInitializers ||
        ((body is Block) &&
            body.statements.isNotEmpty &&
            aopItemInfo.lineNum! >=
                AopUtils.getLineStartNumForStatement(
                    source, body.statements.first)) ||
        (constructor.initializers.isNotEmpty &&
            aopItemInfo.lineNum! >
                AopUtils.getLineStartNumForInitializer(
                    source, constructor.initializers.last))) {
      _curMethodNode = constructor;
      insertStatementsToBody(library, source, constructor.function, aopItemInfo,
          aopInsertStatements);
    }
    //Insert in Initializers
    else {
      final int len = constructor.initializers.length;
      for (int i = 0; i < len; i++) {
        final Initializer initializer = constructor.initializers[i];
        final int lineStart =
            AopUtils.getLineStartNumForInitializer(source, initializer);
        if (lineStart == -1) {
          continue;
        }
        int lineEnds = -1;
        if (i == len - 1) {
          lineEnds = AopUtils.getLineNumBySourceAndOffset(
                  source, constructor.function.fileEndOffset) -
              1;
        } else {
          lineEnds = AopUtils.getLineStartNumForInitializer(
                  source, constructor.initializers[i + 1]) -
              1;
        }
        final int lineNum2Insert = aopItemInfo.lineNum!;
        if (lineNum2Insert > lineStart && lineNum2Insert <= lineEnds) {
          assert(false);
          break;
        } else {
          int statement2InsertPos = -1;
          if (lineNum2Insert <= lineStart) {
            statement2InsertPos = i;
          } else if (lineNum2Insert > lineEnds && i == len - 1) {
            statement2InsertPos = len;
          }
          if (statement2InsertPos != -1) {
            final List<Initializer> tmpInitializers = <Initializer>[];
            for (Statement statement in aopInsertStatements) {
              if (statement is AssertStatement) {
                tmpInitializers.add(AssertInitializer(statement));
              }
            }
            constructor.initializers
                .insertAll(statement2InsertPos, tmpInitializers);
          }
        }
      }
    }
    visitConstructor(constructor);
    onPostTransform(aopItemInfo);
  }

  List<Statement> onPrepareTransform(
      Library library, Node methodNode, AopItemInfo aopItemInfo) {
    final Block block2Insert = aopItemInfo.aopMember!.function!.body as Block;
    final Library aopLibrary = aopItemInfo.aopMember?.parent?.parent as Library;
    final List<Statement> tmpStatements = <Statement>[];
    for (Statement statement in block2Insert.statements) {
      final VariableDeclaration? variableDeclaration =
          AopUtils.checkIfSkipableVarDeclaration(
              _uriToSource[aopLibrary.fileUri]!, statement);

      if (variableDeclaration != null) {
        _mockedVariableDeclaration.add(variableDeclaration);
      } else {
        tmpStatements.add(statement);
      }
    }
    for (LibraryDependency libraryDependency in aopLibrary.dependencies) {
      AopUtils.insertLibraryDependency(
          library, libraryDependency.importedLibraryReference.node as Library);
    }
    if (methodNode is Procedure) {
      for (VariableDeclaration variableDeclaration
          in methodNode.function.namedParameters) {
        _originalVariableDeclaration.putIfAbsent(
            variableDeclaration.name!, () => variableDeclaration);
      }
      for (VariableDeclaration variableDeclaration
          in methodNode.function.positionalParameters) {
        _originalVariableDeclaration.putIfAbsent(
            variableDeclaration.name!, () => variableDeclaration);
      }
    } else if (methodNode is Constructor) {
      for (VariableDeclaration variableDeclaration
          in methodNode.function.namedParameters) {
        _originalVariableDeclaration.putIfAbsent(
            variableDeclaration.name!, () => variableDeclaration);
      }
      for (VariableDeclaration variableDeclaration
          in methodNode.function.positionalParameters) {
        _originalVariableDeclaration.putIfAbsent(
            variableDeclaration.name!, () => variableDeclaration);
      }
    }
    return tmpStatements;
  }

  void onPostTransform(AopItemInfo aopItemInfo) {
    final Block block2Insert = aopItemInfo.aopMember!.function!.body as Block;
    block2Insert.statements.clear();
    _mockedVariableDeclaration.clear();
    _originalVariableDeclaration.clear();
    _curAopLibrary = null;
  }

  void sortTransform() {
    _aopItemInfoList.sort((a, b) => a.importUri.compareTo(b.importUri));
    _aopItemInfoList.sort((a, b) => a.lineNum!.compareTo(b.lineNum!));
  }

  void mergeTransform() {
    late AopItemInfo lastInfo;

    final List<AopItemInfo> removeList = [];

    for (AopItemInfo item in _aopItemInfoList) {
      if (lastInfo == null) {
        lastInfo = item;
        continue;
      }

      if (lastInfo.importUri == item.importUri &&
          lastInfo.clsName == item.clsName &&
          lastInfo.lineNum == item.lineNum) {
        final FunctionNode lastNode = lastInfo.aopMember!.function!;
        final Statement lastStatement = lastNode.body!;

        final FunctionNode node = item.aopMember!.function!;
        final Statement statement = node.body!;

        if (lastStatement is Block && statement is Block) {
          final List<Statement> lastStatements = lastStatement.statements;
          final List<Statement> statements = statement.statements;
          lastStatements.insertAll(0, statements);

          removeList.add(item);
        }
      } else {
        lastInfo = item;
      }
    }
    removeList.forEach((AopItemInfo item) {
      _aopItemInfoList.remove(item);
    });
  }

  void checkIfInsertInFunction(FunctionNode functionNode) {
    if (_curAopStatementsInsertInfo != null) {
      final int lineFrom = AopUtils.getLineNumBySourceAndOffset(
          _curAopStatementsInsertInfo!.source!, functionNode.fileOffset);
      final int lineTo = AopUtils.getLineNumBySourceAndOffset(
          _curAopStatementsInsertInfo!.source!, functionNode.fileEndOffset);
      final int expectedLineNum =
          _curAopStatementsInsertInfo!.aopItemInfo!.lineNum!;
      if (expectedLineNum >= lineFrom && expectedLineNum <= lineTo) {
        final Library library = _curAopStatementsInsertInfo!.library;
        final Source source = _curAopStatementsInsertInfo!.source!;
        final AopItemInfo aopItemInfo = _curAopStatementsInsertInfo!.aopItemInfo!;
        final List<Statement> aopInsertStatements =
            _curAopStatementsInsertInfo!.aopInsertStatements!;
        _curAopStatementsInsertInfo = null;
        functionNode.body = insertStatementsToBody(
            library, source, functionNode, aopItemInfo, aopInsertStatements);
      }
    }
  }

  Statement insertStatementsToBody(Library library, Source source, Node node,
      AopItemInfo aopItemInfo, List<Statement> aopInsertStatements) {
    late Statement body;
    if (node is FunctionNode) {
      body = node!.body!;
      if (body is EmptyStatement) {
        final List<Statement> statements = <Statement>[body];
        body = Block(statements);
        node.body = body;
      }
    } else if (node is Block) {
      body = node;
    }
    if (body is TryCatch && body.fileOffset == -1) {
      final TryCatch tryCatch = body;
      body = tryCatch.body;
    }
    if (body is Block) {
      final List<Statement> statements = body.statements;
      final int len = statements.length;
      for (int i = 0; i < len; i++) {
        final Statement statement = statements[i];
        final Node? nodeToVisitRecursively =
            AopUtils.getNodeToVisitRecursively(statement);
        int lineStart = AopUtils.getLineStartNumForStatement(source, statement);
        int lineEnds = -1;
        final int lineNum2Insert = aopItemInfo.lineNum!;
        int statement2InsertPos = -1;
        if (i != len - 1) {
          lineEnds =
              AopUtils.getLineStartNumForStatement(source, statements[i + 1]) -
                  1;
        }
        if (lineStart < 0 || lineEnds < 0) {
          if (node is FunctionNode) {
            if (lineStart < 0) {
              lineStart =
                  AopUtils.getLineNumBySourceAndOffset(source, node.fileOffset);
            }
            if (lineEnds < 0 && !AopUtils.isAsyncFunctionNode(node)) {
              lineEnds = AopUtils.getLineNumBySourceAndOffset(
                      source, node.fileEndOffset) -
                  1;
            }
          } else if (node is Block) {
            if (_curMethodNode is Procedure) {
              final Procedure procedure = _curMethodNode as Procedure;
              if (AopUtils.isAsyncFunctionNode(procedure.function) &&
                  procedure ==
                      body?.parent?.parent?.parent?.parent?.parent?.parent
                          ?.parent?.parent) {
                if (lineEnds < 0 && i == len - 1) {
                  lineEnds = lineNum2Insert;
                }
              } else {
                if (node.parent is FunctionNode) {
                  final FunctionNode functionNode = node.parent! as FunctionNode;
                  if (lineStart < 0)
                    lineStart = AopUtils.getLineNumBySourceAndOffset(
                        source, functionNode.fileOffset);
                  if (lineEnds < 0)
                    lineEnds = AopUtils.getLineNumBySourceAndOffset(
                        source, functionNode.fileEndOffset);
                }
              }
            }
          }
        }

        if ((lineNum2Insert >= lineStart && lineNum2Insert < lineEnds) ||
            (lineEnds < lineStart && lineEnds != -1) ||
            lineStart == -1) {
          if (nodeToVisitRecursively != null) {
            _curAopStatementsInsertInfo = AopStatementsInsertInfo(
                library: library,
                source: source,
                constructor: null,
                procedure: null,
                node: nodeToVisitRecursively,
                aopItemInfo: aopItemInfo,
                aopInsertStatements: aopInsertStatements);
            visitNode(nodeToVisitRecursively);

            continue;
          }
        }
        if (lineNum2Insert == lineStart - 1 || lineNum2Insert == lineStart) {
          statement2InsertPos = i;
        } else if (lineEnds != -1 && lineNum2Insert == lineEnds + 1) {
          statement2InsertPos = i + 1;
        } else if (lineNum2Insert >= lineEnds && i == len - 1) {
          statement2InsertPos = len;
        }
        if (statement2InsertPos != -1) {
          _curAopStatementsInsertInfo = null;

          statements.insertAll(statement2InsertPos, aopInsertStatements);
          _curAopLibrary = aopItemInfo.aopMember?.parent?.parent as Library;
          visitNode(node);
          break;
        }
      }
    } else {
      assert(false);
    }
    return body;
  }

  void visitNode(Object node) {
    if (node is Constructor) {
      visitConstructor(node);
    } else if (node is Procedure) {
      visitProcedure(node);
    } else if (node is LabeledStatement) {
      visitLabeledStatement(node);
    } else if (node is FunctionNode) {
      visitFunctionNode(node);
    } else if (node is Block) {
      visitBlock(node);
    }
  }
}
