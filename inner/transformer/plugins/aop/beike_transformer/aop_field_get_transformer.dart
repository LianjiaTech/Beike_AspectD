// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../transformer/aop_iteminfo.dart';
import '../transformer/aop_tranform_utils.dart';

class AopFieldGetImplTransformer extends Transformer {
  AopFieldGetImplTransformer(
      this._aopItemInfoList);

  final List<AopItemInfo> _aopItemInfoList;
  Library? _curLibrary;
  Class ?_curClass;

  @override
  Library visitLibrary(Library node) {
    _curLibrary = node;
    node.transformChildren(this);
    return node;
  }

  @override
  Class visitClass(Class node) {
    _curClass = node;
    node.transformChildren(this);
    return node;
  }

  @override
  Expression visitStaticGet(StaticGet node) {
    String? importUri, clsName, fieldName;

    // importUri = _curLibrary!.importUri.toString();

    importUri = node?.targetReference?.canonicalName?.reference?.canonicalName
        ?.nonRootTop?.name;
    clsName = node?.targetReference?.canonicalName?.parent?.parent?.name;
    fieldName = node?.targetReference?.canonicalName?.name;

    final AopItemInfo aopItemInfo = _filterAopItemInfo(
        _aopItemInfoList, importUri!, clsName!, fieldName!, true)!;

    if (aopItemInfo != null) {
      final Arguments redirectArguments = Arguments.empty();
      redirectArguments.positional.add(NullLiteral());
      final StaticInvocation staticInvocationNew =
          StaticInvocation(aopItemInfo.aopMember as Procedure, redirectArguments);

      return staticInvocationNew;
    }

    return super.visitStaticGet(node) as Expression;
  }

  @override
  Expression visitInstanceGet(InstanceGet node) {
    String importUri, clsName, fieldName;

    importUri = _curLibrary!.importUri.toString();
    clsName = _curClass!.name;
    fieldName = node.name.text;

    final AopItemInfo aopItemInfo = _filterAopItemInfo(
        _aopItemInfoList, importUri, clsName, fieldName, false)!;

    if (aopItemInfo != null) {
      final Arguments redirectArguments = Arguments.empty();

      redirectArguments.positional.add(NullLiteral());

      final StaticInvocation staticInvocationNew =
          StaticInvocation(aopItemInfo.aopMember as Procedure, redirectArguments);

      return staticInvocationNew;
    }

    return super.visitInstanceGet(node) as Expression;
  }

  //Filter AopInfoMap for specific callsite.
  AopItemInfo? _filterAopItemInfo(List<AopItemInfo> aopItemInfoList,
      String importUri, String clsName, String fieldName, bool isStatic) {
    //Reverse sorting so that the newly added Aspect might override the older ones.
    importUri ??= '';
    clsName ??= '';
    fieldName ??= '';
    final int aopItemInfoCnt = aopItemInfoList.length;
    for (int i = aopItemInfoCnt - 1; i >= 0; i--) {
      final AopItemInfo aopItemInfo = aopItemInfoList[i];

      if (aopItemInfo.excludeCoreLib &&
          _curLibrary!.importUri.toString().startsWith('package:flutter/')) {
        continue;
      }

      if (aopItemInfo.isRegex) {
        if (RegExp(aopItemInfo.importUri).hasMatch(importUri) &&
            RegExp(aopItemInfo.clsName).hasMatch(clsName) &&
            RegExp(aopItemInfo.fieldName!).hasMatch(fieldName) &&
            isStatic == aopItemInfo.isStatic) {
          return aopItemInfo;
        }
      } else {
        if (aopItemInfo.importUri == importUri &&
            aopItemInfo.clsName == clsName &&
            aopItemInfo.fieldName == fieldName &&
            isStatic == aopItemInfo.isStatic) {
          return aopItemInfo;
        }
      }
    }
    return null;
  }

  //Will create stub and insert call branch in proceed.
  void createPointcutStubProcedure(AopItemInfo aopItemInfo, String stubKey,
      Class pointCutClass, Statement bodyStatements, bool shouldReturn) {
    final Procedure procedure = AopUtils.createStubProcedure(
        Name(stubKey, AopUtils.pointCutProceedProcedure!.name.library),
        aopItemInfo,
        AopUtils.pointCutProceedProcedure as Procedure,
        bodyStatements,
        shouldReturn);
    pointCutClass.procedures.add(procedure);
    AopUtils.insertProceedBranch(pointCutClass, procedure, shouldReturn);
  }
}
