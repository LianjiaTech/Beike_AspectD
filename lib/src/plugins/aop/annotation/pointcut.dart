// @dart=2.8

/// Object carrying callsite information and methods which can enable you to
/// call the original implementation.
@pragma('vm:entry-point')
class PointCut {
  /// PointCut default constructor.
  @pragma('vm:entry-point')
  PointCut(this.sourceInfos, this.target, this.function, this.stubKey,
      this.positionalParams, this.namedParams, this.members, this.annotations);

  static PointCut pointCut() {
    return PointCut(null, null, null, null, null, null, null, null);
  }

  /// Source infomation like file, linenum, etc for a call.
  final Map<dynamic, dynamic> sourceInfos;

  /// Target where a call is operating on, like x for x.foo().
  final Object target;

  /// Function name for a call, like foo for x.foo().
  final String function;

  /// Unique key which can help the proceed function to distinguish a
  /// mocked call.
  final String stubKey;

  /// Positional parameters for a call.
  final List<dynamic> positionalParams;

  /// Named parameters for a call.
  final Map<dynamic, dynamic> namedParams;

  /// Class's members. In Call mode, it's caller class's members. In execute mode,  it's execution class's members.
  final Map<dynamic, dynamic> members;

  /// Class's annotations. In Call mode, it's caller class's annotations. In execute mode,  it's execution class's annotations.
  final Map<dynamic, dynamic> annotations;

  /// Unified entrypoint to call a original method,
  /// the method body is generated dynamically when being transformed in
  /// compile time.
  @pragma('vm:entry-point')
  Object proceed() {
    return null;
  }
}
