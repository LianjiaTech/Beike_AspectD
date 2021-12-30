import '../annotation/annotation_info.dart';

/// Call grammar is working on those callsites for the annotated method.
@pragma('vm:entry-point')
class Add extends AnnotationInfo {
  /// Call grammar default constructor.
  const factory Add(String importUri, String clsName,
      {bool isRegex, String superCls}) = Add._;

  @pragma('vm:entry-point')
  const Add._(String importUri, String clsName, {bool? isRegex, this.superCls})
      : super(importUri: importUri, clsName: clsName, isRegex: isRegex);

  /// Indicating which classes inherited from the superCls to operate on.
  /// This is only meaningful for regex add grammer.
  final String? superCls;
}
