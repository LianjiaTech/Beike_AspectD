import 'package:kernel/ast.dart';
import 'package:vm/target/flutter.dart';

import 'beike_transformer/aop_addimpl_transformer.dart';
import 'beike_transformer/aop_field_get_transformer.dart';
import 'transformer/aop_callimpl_transformer.dart';
import 'transformer/aop_executeimpl_transformer.dart';
import 'transformer/aop_injectimpl_transformer.dart';
import 'transformer/aop_iteminfo.dart';
import 'transformer/aop_mode.dart';
import 'transformer/aop_tranform_utils.dart';

class AopWrapperTransformer extends FlutterProgramTransformer {
  AopWrapperTransformer({this.platformStrongComponent});

  List<AopItemInfo> aopItemInfoList = <AopItemInfo>[];
  Map<String, Library> componentLibraryMap = <String, Library>{};
  Component platformStrongComponent;

  @override
  void transform(Component program, {void Function(String msg) logger}) {
    for (Library library in program.libraries) {
      componentLibraryMap.putIfAbsent(
          library.importUri.toString(), () => library);
    }
    program.libraries.forEach(_checkIfCompleteLibraryReference);
    final List<Library> libraries = program.libraries;

    if (libraries.isEmpty) {
      return;
    }

    _resolveAopProcedures(libraries);

    Procedure pointCutProceedProcedure;
    Procedure listGetProcedure;
    Procedure mapGetProcedure;
    //Search the PointCut class first
    final List<Library> concatLibraries = <Library>[
      ...libraries,
      ...platformStrongComponent != null
          ? platformStrongComponent.libraries
          : <Library>[]
    ];
    final Map<Uri, Source> concatUriToSource = <Uri, Source>{}
      ..addAll(program.uriToSource)
      ..addAll(platformStrongComponent != null
          ? platformStrongComponent.uriToSource
          : <Uri, Source>{});
    final Map<String, Library> libraryMap = <String, Library>{};
    for (Library library in concatLibraries) {
      libraryMap.putIfAbsent(library.importUri.toString(), () => library);
      if (pointCutProceedProcedure != null &&
          listGetProcedure != null &&
          mapGetProcedure != null) {
        continue;
      }

      if (library.name == 'dart.core') {
        AopUtils.coreLib = library;
      }

      final Uri importUri = library.importUri;
      for (Class cls in library.classes) {
        final String clsName = cls.name;
        if (clsName == AopUtils.kAopAnnotationClassPointCut &&
            importUri.toString() == AopUtils.kImportUriPointCut) {
          for (Procedure procedure in cls.procedures) {
            if (procedure.name.text == AopUtils.kAopPointcutProcessName) {
              pointCutProceedProcedure = procedure;
            }
          }
        }
        if (clsName == 'List' && importUri.toString() == 'dart:core') {
          for (Procedure procedure in cls.procedures) {
            if (procedure.name.text == '[]') {
              listGetProcedure = procedure;
            }
          }
        }
        if (clsName == 'Map' && importUri.toString() == 'dart:core') {
          for (Procedure procedure in cls.procedures) {
            if (procedure.name.text == '[]') {
              mapGetProcedure = procedure;
            }
          }
        }
      }
    }
    final List<AopItemInfo> callInfoList = <AopItemInfo>[];
    final List<AopItemInfo> executeInfoList = <AopItemInfo>[];
    final List<AopItemInfo> injectInfoList = <AopItemInfo>[];
    final List<AopItemInfo> addInfoList = <AopItemInfo>[];
    final List<AopItemInfo> initializerInfoList = <AopItemInfo>[];
    final List<AopItemInfo> fieldGetInfoList = <AopItemInfo>[];

    for (AopItemInfo aopItemInfo in aopItemInfoList) {
      if (aopItemInfo.mode == AopMode.Call) {
        callInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.Execute) {
        executeInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.Inject) {
        injectInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.Add) {
        addInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.FieldInitializer) {
        initializerInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.FieldGet) {
        fieldGetInfoList.add(aopItemInfo);
      }
    }

    AopUtils.pointCutProceedProcedure = pointCutProceedProcedure;
    AopUtils.listGetProcedure = listGetProcedure;
    AopUtils.mapGetProcedure = mapGetProcedure;
    AopUtils.platformStrongComponent = platformStrongComponent;

    // Aop call transformer
    if (callInfoList.isNotEmpty) {
      final AopCallImplTransformer aopCallImplTransformer =
          AopCallImplTransformer(
        callInfoList,
        libraryMap,
        concatUriToSource,
      );

      for (int i = 0; i < libraries.length; i++) {
        final Library library = libraries[i];
        aopCallImplTransformer.visitLibrary(library);
      }
    }

    if (addInfoList.isNotEmpty) {
      final AopAddImplTransformer aopAddImplTransformer =
          AopAddImplTransformer(addInfoList, concatUriToSource);
      for (int i = 0; i < libraries.length; i++) {
        final Library library = libraries[i];
        aopAddImplTransformer.visitLibrary(library);
      }
    }

    // Aop execute transformer
    if (executeInfoList.isNotEmpty) {
      AopExecuteImplTransformer(executeInfoList, libraryMap, concatUriToSource)
        ..aopTransform();
    }
    // Aop inject transformer
    if (injectInfoList.isNotEmpty) {
      AopInjectImplTransformer(injectInfoList, libraryMap, concatUriToSource)
        ..aopTransform();
    }

    // Aop call transformer
    if (fieldGetInfoList.isNotEmpty) {
      final AopFieldGetImplTransformer aopFieldGetImplTransformer =
          AopFieldGetImplTransformer(
        fieldGetInfoList,
        libraryMap,
        concatUriToSource,
      );

      for (int i = 0; i < libraries.length; i++) {
        final Library library = libraries[i];
        aopFieldGetImplTransformer.visitLibrary(library);
      }
    }
  }

  void _resolveAopProcedures(Iterable<Library> libraries) {
    for (Library library in libraries) {
      final List<Class> classes = library.classes;
      for (Class cls in classes) {
        final bool aspectdEnabled =
            AopUtils.checkIfClassEnableAspectd(cls.annotations);
        if (!aspectdEnabled) {
          continue;
        }
        for (Member member in cls.members) {
          if (!(member is Member)) {
            continue;
          }
          final AopItemInfo aopItemInfo = _processAopMember(member);
          if (aopItemInfo != null) {
            aopItemInfoList.add(aopItemInfo);
          }
        }
      }
    }
  }

  AopItemInfo _processAopMember(Member member) {
    AopItemInfo aopItemInfoRet;
    for (Expression annotation in member.annotations) {
      if (annotation is ConstantExpression) {
        final ConstantExpression constantExpression = annotation;
        final Constant constant = constantExpression.constant;
        if (constant is InstanceConstant) {
          final InstanceConstant instanceConstant = constant;
          final CanonicalName canonicalName =
              instanceConstant.classReference.canonicalName;
          constant.classReference.node ??= AopUtils.getNodeFromCanonicalName(
              componentLibraryMap, canonicalName);
          constant.fieldValues
              .forEach((Reference reference, Constant constant) {
            reference.node ??= AopUtils.getNodeFromCanonicalName(
                componentLibraryMap, reference?.canonicalName);
          });
          final AopMode aopMode = AopUtils.getAopModeByNameAndImportUri(
              canonicalName.name, canonicalName?.parent?.name);
          if (aopMode == null) {
            continue;
          }
          String importUri;
          String clsName;
          String superClsName;
          String methodName;
          String fieldName;
          bool isRegex = false;
          bool excludeCoreLib = false;
          int lineNum;
          bool isStatic = false;

          instanceConstant.fieldValues
              .forEach((Reference reference, Constant constant) {
            if (constant is StringConstant) {
              final String value = constant.value;
              if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationImportUri) {
                importUri = value;
              } else if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationClsName) {
                clsName = value;
              } else if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationMethodName) {
                methodName = value;
              } else if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationSuperClsName) {
                superClsName = value;
              } else if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationfieldName) {
                fieldName = value;
              }
            }
            if (reference?.canonicalName?.name ==
                AopUtils.kAopAnnotationLineNum) {
              if (constant is DoubleConstant) {
                final int value = constant.value.toInt();
                lineNum = value - 1;
              } else if (constant is IntConstant) {
                final int value = constant.value;
                lineNum = value - 1;
              }
            }
            if (constant is BoolConstant) {
              final bool value = constant.value;
              if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationIsRegex) {
                isRegex = value;
              } else if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationExcludeCoreLib) {
                excludeCoreLib = value;
              } else if (reference?.canonicalName?.name ==
                  AopUtils.kAopAnnotationIsStatic) {
                isStatic = value;
              }
            }
          });

          if (aopMode != AopMode.FieldGet) {
            if (methodName != null) {
              if (methodName
                  .startsWith(AopUtils.kAopAnnotationInstanceMethodPrefix)) {
                methodName = methodName.substring(
                    AopUtils.kAopAnnotationInstanceMethodPrefix.length);
              } else if (methodName
                  .startsWith(AopUtils.kAopAnnotationStaticMethodPrefix)) {
                methodName = methodName.substring(
                    AopUtils.kAopAnnotationStaticMethodPrefix.length);
                isStatic = true;
              }
            }
          }

          member.annotations.remove(annotation);

          return AopItemInfo(
              importUri: importUri,
              clsName: clsName,
              methodName: methodName,
              isStatic: isStatic,
              aopMember: member,
              mode: aopMode,
              isRegex: isRegex,
              superCls: superClsName,
              lineNum: lineNum,
              excludeCoreLib: excludeCoreLib,
              fieldName: fieldName);
        }
      }
      //Debug Mode
      else if (annotation is ConstructorInvocation) {
        final ConstructorInvocation constructorInvocation = annotation;
        final Class cls = constructorInvocation?.targetReference?.node?.parent;
        final Library clsParentLib = cls?.parent;
        final AopMode aopMode = AopUtils.getAopModeByNameAndImportUri(
            cls?.name, clsParentLib?.importUri?.toString());
        if (aopMode == null) {
          continue;
        }
        final StringLiteral stringLiteral0 =
            constructorInvocation.arguments.positional[0];
        final String importUri = stringLiteral0.value;
        final StringLiteral stringLiteral1 =
            constructorInvocation.arguments.positional[1];
        final String clsName = stringLiteral1.value;
        final StringLiteral stringLiteral2 =
            constructorInvocation.arguments.positional.length > 2
                ? constructorInvocation.arguments.positional[2]
                : StringLiteral('');
        String methodName = stringLiteral2.value;
        bool isRegex = false;
        int lineNum;
        String superCls;

        for (NamedExpression namedExpression
            in constructorInvocation.arguments.named) {
          if (namedExpression.name == AopUtils.kAopAnnotationLineNum) {
            final IntLiteral intLiteral = namedExpression.value;
            lineNum = intLiteral.value - 1;
          }
          if (namedExpression.name == AopUtils.kAopAnnotationSuperClsName) {
            final StringLiteral stringLiteral = namedExpression.value;
            superCls = stringLiteral.value;
          }
          if (namedExpression.name == AopUtils.kAopAnnotationIsRegex) {
            final BoolLiteral boolLiteral = namedExpression.value;
            isRegex = boolLiteral.value;
          }
        }

        bool isStatic = false;
        if (methodName
            .startsWith(AopUtils.kAopAnnotationInstanceMethodPrefix)) {
          methodName = methodName
              .substring(AopUtils.kAopAnnotationInstanceMethodPrefix.length);
        } else if (methodName
            .startsWith(AopUtils.kAopAnnotationStaticMethodPrefix)) {
          methodName = methodName
              .substring(AopUtils.kAopAnnotationStaticMethodPrefix.length);
          isStatic = true;
        }

        String fieldName = '';
        if (aopMode == AopMode.FieldInitializer) {
          final StringLiteral stringLiteral3 =
              constructorInvocation.arguments.positional.length > 3
                  ? constructorInvocation.arguments.positional[3]
                  : StringLiteral('');
          fieldName = stringLiteral3.value;
        }

        if (aopMode == AopMode.FieldGet) {
          final StringLiteral stringLiteral3 =
              constructorInvocation.arguments.positional.length > 2
                  ? constructorInvocation.arguments.positional[2]
                  : StringLiteral('');
          fieldName = stringLiteral3.value;

          final BoolLiteral isStaticLiteral =
              constructorInvocation.arguments.positional.length > 3
                  ? constructorInvocation.arguments.positional[3]
                  : BoolLiteral(false);
          isStatic = isStaticLiteral.value;
        }

        member.annotations.remove(annotation);

        return AopItemInfo(
            importUri: importUri,
            clsName: clsName,
            methodName: methodName,
            isStatic: isStatic,
            aopMember: member,
            mode: aopMode,
            superCls: superCls,
            isRegex: isRegex,
            lineNum: lineNum,
            fieldName: fieldName);
      }
    }
    return aopItemInfoRet;
  }

  void _checkIfCompleteLibraryReference(Library library) {
    for (LibraryDependency libraryDependency
        in library.dependencies ?? <LibraryDependency>[]) {
      libraryDependency.importedLibraryReference.node ??=
          AopUtils.getNodeFromCanonicalName(componentLibraryMap,
              libraryDependency.importedLibraryReference.canonicalName);
    }
  }
}
