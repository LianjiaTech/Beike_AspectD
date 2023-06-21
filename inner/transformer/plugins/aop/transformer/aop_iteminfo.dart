import 'package:kernel/ast.dart';

import 'aop_mode.dart';
import 'aop_tranform_utils.dart';

class AopItemInfo {
  AopItemInfo(
      {required this.mode,
      required this.importUri,
      required this.clsName,
      this.methodName,
      this.isStatic,
      this.aopMember,
      this.isRegex,
      this.superCls,
      this.lineNum,
      this.excludeCoreLib = false,
      this.fieldName});

  final AopMode mode;
  final String importUri;
  final String clsName;
  final String? methodName;
  final bool? isStatic;
  final bool? isRegex;
  final String? superCls;
  final Member? aopMember;
  final int? lineNum;
  final bool? excludeCoreLib;
  final String? fieldName;
  static String uniqueKeyForMethod(
      String importUri, String clsName, String methodName, bool isStatic,
      {int? lineNum}) {
    return (importUri ?? '') +
        AopUtils.kAopUniqueKeySeperator +
        (clsName ?? '') +
        AopUtils.kAopUniqueKeySeperator +
        (methodName ?? '') +
        AopUtils.kAopUniqueKeySeperator +
        (isStatic == true ? '+' : '-') +
        (lineNum != null ? (AopUtils.kAopUniqueKeySeperator + '$lineNum') : '');
  }
}
