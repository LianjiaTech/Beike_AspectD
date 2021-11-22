import '../annotation/annotation_info.dart';

/// Call grammar is working on those callsites for the annotated method.
@pragma('vm:entry-point')
class Add extends AnnotationInfo {
  /// Call grammar default constructor.
  const factory Add(String importUri, String clsName,
      {bool isRegex, String superCls}) = Add._;

  @pragma('vm:entry-point')
  const Add._(String importUri, String clsName,
      {bool isRegex, String superCls})
      : super(
            importUri: importUri,
            clsName: clsName,
            isRegex: isRegex,
            superCls: superCls);
}
