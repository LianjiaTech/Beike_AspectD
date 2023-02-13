import '../annotation/annotation_info.dart';

/// Field get grammar is working on those callsites for the annotated method.
@pragma('vm:entry-point')
class FieldGet extends AnnotationInfo {
  /// Call grammar default constructor.
  const factory FieldGet(String importUri, String clsName, String fieldName, bool isStatic,
      {bool isRegex}) = FieldGet._;

  @pragma('vm:entry-point')
  const FieldGet._(String importUri, String clsName, this.fieldName, this.isStatic,
      {bool? isRegex})
      : super(
            importUri: importUri,
            clsName: clsName,
            isRegex: isRegex);

  final String fieldName;
  final bool isStatic;
}
