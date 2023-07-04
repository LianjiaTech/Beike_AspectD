import 'package:kernel/ast.dart';
import 'package:kernel/visitor.dart';
import '../transformer/aop_iteminfo.dart';
import '../transformer/aop_tranform_utils.dart';

class AopAddImplTransformer extends RecursiveVisitor<void> {
  AopAddImplTransformer(this._aopItemInfoList, this._uriToSource);

  final List<AopItemInfo> _aopItemInfoList;
  final Map<Uri, Source> _uriToSource;

  Library? _curLibrary;

  @override
  void visitLibrary(Library node) {
    _curLibrary = node;
    node.visitChildren(this);
  }

  @override
  void visitClass(Class node) {
    final String procedureImportUri =
        (node.parent as Library).importUri.toString();

    List<AopItemInfo>? items = _filterAopItemInfo(
        _aopItemInfoList, procedureImportUri, node.name, node.superclass);
    if (items != null && items.isNotEmpty) {
      for (AopItemInfo item in items) {
        //Exclude hook class
        if (item.aopMember!.parent!.parent != _curLibrary) {
          insertMethod4Class(item, node);
        }
      }
    }
  }

  // ignore: flutter_style_todos
  void insertMethod4Class(AopItemInfo aopItemInfo, Class pointCutClass) {
    final Procedure originProcedure = aopItemInfo.aopMember!.function!.parent as Procedure;

    for (Member member in pointCutClass.members) {
      if (member.name.text == originProcedure.name.text) {
        return;
      }
    }

    AopUtils.insertLibraryDependency(
        _curLibrary!, aopItemInfo.aopMember!.parent!.parent as Library);

    final Arguments redirectArguments = Arguments.empty();
    final Map<String, String> sourceInfo =
        AopUtils.calcSourceInfo(_uriToSource, _curLibrary!, 0);

    final FunctionNode originFunctionNode = aopItemInfo.aopMember!.function as FunctionNode;

    final Arguments originArguments =
        AopUtils.argumentsFromFunctionNode(originFunctionNode);

    final Arguments pointCutConstructorArguments = Arguments.empty();
    final List<MapLiteralEntry> sourceInfos = <MapLiteralEntry>[];
    sourceInfo?.forEach((String key, String value) {
      sourceInfos.add(MapLiteralEntry(StringLiteral(key), StringLiteral(value)));
    });
    pointCutConstructorArguments.positional.add(MapLiteral(sourceInfos));
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());

    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());

    final Class pointCutProceedProcedureCls =
        AopUtils.pointCutProceedProcedure!.parent as Class;
    final ConstructorInvocation pointCutConstructorInvocation =
        ConstructorInvocation(pointCutProceedProcedureCls.constructors.first,
            pointCutConstructorArguments);

    redirectArguments.positional.add(pointCutConstructorInvocation);

    if (originArguments.positional.length > 1) {
      for (int i = 1; i < originArguments.positional.length; i++) {
        final Expression expression = originArguments.positional[i];
        redirectArguments.positional.add(expression);
      }
    }

    // TODO(p): 暂时只传sourceInfos，传其他值会导致编译失败，后续处理
    // AopUtils.concatArgumentsForAopMethod(
    //     sourceInfo,
    //     redirectArguments,
    //     '-1',
    //     StringLiteral(_curLibrary.importUri.toString()),
    //     aopItemInfo.aopMember,
    //     originArguments,
    //     pointCutClass);
    //
    // for (int i = 0; i < originArguments.positional.length; i++) {
    //   if (i == 0) {
    //     continue;
    //   }
    //   final Expression positional = originArguments.positional[i];
    //   redirectArguments.positional.add(positional);
    // }

    redirectArguments.named.addAll(originArguments.named);

    // pointCutConstructorInvocation.arguments.positional
    final Class cls = aopItemInfo.aopMember!.parent as Class;
    final ConstructorInvocation redirectConstructorInvocation =
        ConstructorInvocation.byReference(
            cls.constructors.first.reference, Arguments(<Expression>[]));
    final InstanceInvocation methodInvocationNew = InstanceInvocation(InstanceAccessKind.Instance,
        redirectConstructorInvocation,
        aopItemInfo.aopMember!.name,
        redirectArguments, interfaceTarget: aopItemInfo.aopMember as Procedure, functionType: aopItemInfo.aopMember!.getterType as FunctionType);

    final bool shouldReturn =
        !(originProcedure.function.returnType is VoidType);
    final DartType returnType = shouldReturn
        ? AopUtils.deepCopyASTNode(originProcedure.function.returnType)
        : const VoidType();
    final List<TypeParameter> typeParameters =
        AopUtils.deepCopyASTNodes<TypeParameter>(
            originProcedure.function.typeParameters);

    final Block bodyStatements = Block(<Statement>[]);
    if (shouldReturn) {
      bodyStatements.addStatement(ReturnStatement(methodInvocationNew));
    } else {
      bodyStatements.addStatement(ExpressionStatement(methodInvocationNew));
    }

    final FunctionNode functionNode = FunctionNode(bodyStatements,
        typeParameters: typeParameters,
        positionalParameters: originProcedure.function.positionalParameters,
        namedParameters: originProcedure.function.namedParameters,
        requiredParameterCount: originProcedure.function.requiredParameterCount,
        returnType: returnType,
        asyncMarker: originProcedure.function.asyncMarker,
        dartAsyncMarker: originProcedure.function.dartAsyncMarker);

    final Name name = Name(originProcedure.name.text, _curLibrary);

    final Procedure procedure = Procedure(
      name,
      ProcedureKind.Method,
      functionNode,
      isStatic: originProcedure.isStatic,
      fileUri: pointCutClass.fileUri,
    );

    pointCutClass.procedures.add(procedure);
  }

  //Filter AopInfoMap for specific class.
  List<AopItemInfo> _filterAopItemInfo(List<AopItemInfo> aopItemInfoList,
      String importUri, String clsName, Class? superClazz) {
    //Reverse sorting so that the newly added Aspect might override the older ones.
    importUri ??= '';
    clsName ??= '';
    final int aopItemInfoCnt = aopItemInfoList.length;

    final List<AopItemInfo> items = <AopItemInfo>[];
    for (int i = aopItemInfoCnt - 1; i >= 0; i--) {
      final AopItemInfo aopItemInfo = aopItemInfoList[i];

      if (aopItemInfo.isRegex) {
        if (RegExp(aopItemInfo.importUri).hasMatch(importUri) &&
            RegExp(aopItemInfo.clsName).hasMatch(clsName)) {
          bool shouldAdd = true;

          if (aopItemInfo.superCls != null) {
            shouldAdd = false;
            while (superClazz != null) {
              if (superClazz.name == aopItemInfo.superCls) {
                shouldAdd = true;
                break;
              }
              superClazz = superClazz!.superclass!;
            }
          }

          if (shouldAdd == true) {
            items.add(aopItemInfo);
          }
        }
      } else {
        if (aopItemInfo.importUri == importUri &&
            aopItemInfo.clsName == clsName) {
          items.add(aopItemInfo);
        }
      }
    }
    return items;
  }
}
