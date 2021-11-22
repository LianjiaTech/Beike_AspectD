import 'package:kernel/ast.dart';
import 'package:kernel/visitor.dart';
import 'package:front_end/src/fasta/kernel/kernel_ast_api.dart';
import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/transformations/type_flow/table_selector_assigner.dart';

import '../transformer/aop_iteminfo.dart';
import '../transformer/aop_tranform_utils.dart';

class AopAddImplTransformer extends RecursiveVisitor<void> {
  AopAddImplTransformer(this._aopItemInfoList, this._uriToSource);

  final List<AopItemInfo> _aopItemInfoList;
  final Map<Uri, Source> _uriToSource;

  Library _curLibrary;

  @override
  void visitLibrary(Library node) {
    _curLibrary = node;
    node.visitChildren(this);
  }

  @override
  void visitClass(Class node) {
    final String procedureImportUri =
        (node.parent as Library).importUri.toString();

    final List<AopItemInfo> items = _filterAopItemInfo(
        _aopItemInfoList, procedureImportUri, node.name, node.superclass);
    if (items.isNotEmpty) {
      for (AopItemInfo item in items) {
        //Exclude hook class
        if (item.aopMember.parent.parent != _curLibrary) {
          insertMethod4Class(item, node);
        }
      }
    }
  }

  void insertMethod4Class(AopItemInfo aopItemInfo, Class pointCutClass) {
    final Procedure originProcedure = aopItemInfo.aopMember.function.parent;

    for (Member member in pointCutClass.members) {
      if (member.name.name == originProcedure.name.name) {
        return;
      }
    }

    AopUtils.insertLibraryDependency(
        _curLibrary, aopItemInfo.aopMember.parent.parent);

    final Arguments redirectArguments = Arguments.empty();
    final Map<String, String> sourceInfo =
        AopUtils.calcSourceInfo(_uriToSource, _curLibrary, 0);

    final FunctionNode originFunctionNode = aopItemInfo.aopMember.function;

    final Arguments originArguments =
        AopUtils.argumentsFromFunctionNode(originFunctionNode);

    final Arguments pointCutConstructorArguments = Arguments.empty();
    final List<MapEntry> sourceInfos = <MapEntry>[];
    sourceInfo?.forEach((String key, String value) {
      sourceInfos.add(MapEntry(StringLiteral(key), StringLiteral(value)));
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
        AopUtils.pointCutProceedProcedure.parent;
    final ConstructorInvocation pointCutConstructorInvocation =
        ConstructorInvocation(pointCutProceedProcedureCls.constructors.first,
            pointCutConstructorArguments);

    redirectArguments.positional.add(pointCutConstructorInvocation);
    redirectArguments.named.addAll(originArguments.named);

    final Class cls = aopItemInfo.aopMember.parent;
    final ConstructorInvocation redirectConstructorInvocation =
        ConstructorInvocation.byReference(
            cls.constructors.first.reference, Arguments(<Expression>[]));
    final MethodInvocation methodInvocationNew = MethodInvocation(
        redirectConstructorInvocation,
        aopItemInfo.aopMember.name,
        redirectArguments);

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

    final Name name = Name(originProcedure.name.name, _curLibrary);

    final Procedure procedure = Procedure(
      name,
      ProcedureKind.Method,
      functionNode,
      isStatic: originProcedure.isStatic,
      fileUri: pointCutClass.fileUri,
    );

    pointCutClass.addMember(procedure);
  }

  //Filter AopInfoMap for specific class.
  List<AopItemInfo> _filterAopItemInfo(List<AopItemInfo> aopItemInfoList,
      String importUri, String clsName, Class superClazz) {
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
              superClazz = superClazz.superclass;
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
