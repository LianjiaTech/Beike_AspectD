// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Converters and codecs for converting between Protobuf and [Info] classes.
import 'dart:convert';

import 'package:fixnum/fixnum.dart';

import 'info.dart';
import 'src/proto/info.pb.dart';
import 'src/util.dart';

export 'src/proto/info.pb.dart';

class ProtoToAllInfoConverter extends Converter<AllInfoPB, AllInfo> {
  @override
  AllInfo convert(AllInfoPB input) {
    // TODO(lorenvs): Implement this conversion. It is unlikely to be used
    // by production code since the goal of the proto codec is to consume this
    // information from other languages. However, it is useful for roundtrip
    // testing, so we should support it.
    throw UnimplementedError('ProtoToAllInfoConverter is not implemented');
  }
}

class AllInfoToProtoConverter extends Converter<AllInfo, AllInfoPB> {
  final Map<Info, Id> ids = {};
  final Set<int> usedIds = <int>{};

  Id idFor(Info info) {
    var serializedId = ids[info];
    if (serializedId != null) return serializedId;

    assert(info is LibraryInfo ||
        info is ConstantInfo ||
        info is OutputUnitInfo ||
        info is ClassInfo ||
        info.parent != null);

    int id;
    if (info is ConstantInfo) {
      // No name and no parent, so `longName` isn't helpful
      assert(info.name.isEmpty);
      assert(info.parent == null);
      // Instead, use the content of the code.
      id = info.code.first.text.hashCode;
    } else {
      id = longName(info, useLibraryUri: true, forId: true).hashCode;
    }
    while (!usedIds.add(id)) {
      id++;
    }
    serializedId = Id(info.kind, id);
    return ids[info] = serializedId;
  }

  @override
  AllInfoPB convert(AllInfo input) => _convertToAllInfoPB(input);

  DependencyInfoPB _convertToDependencyInfoPB(DependencyInfo info) {
    var result = DependencyInfoPB();
    final targetId = idFor(info.target).serializedId;
    result.targetId = targetId;
    if (info.mask != null) {
      result.mask = info.mask!;
    }
    return result;
  }

  static ParameterInfoPB _convertToParameterInfoPB(ParameterInfo info) {
    return ParameterInfoPB()
      ..name = info.name
      ..type = info.type
      ..declaredType = info.declaredType;
  }

  LibraryInfoPB _convertToLibraryInfoPB(LibraryInfo info) {
    final proto = LibraryInfoPB()..uri = info.uri.toString();

    proto.childrenIds
        .addAll(info.topLevelFunctions.map((func) => idFor(func).serializedId));
    proto.childrenIds.addAll(
        info.topLevelVariables.map((field) => idFor(field).serializedId));
    proto.childrenIds
        .addAll(info.classes.map((clazz) => idFor(clazz).serializedId));
    proto.childrenIds.addAll(
        info.classTypes.map((classType) => idFor(classType).serializedId));
    proto.childrenIds
        .addAll(info.typedefs.map((def) => idFor(def).serializedId));

    return proto;
  }

  ClassInfoPB _convertToClassInfoPB(ClassInfo info) {
    final proto = ClassInfoPB()..isAbstract = info.isAbstract;

    proto.childrenIds
        .addAll(info.functions.map((func) => idFor(func).serializedId));
    proto.childrenIds
        .addAll(info.fields.map((field) => idFor(field).serializedId));

    return proto;
  }

  ClassTypeInfoPB _convertToClassTypeInfoPB(ClassTypeInfo info) {
    return ClassTypeInfoPB();
  }

  static FunctionModifiersPB _convertToFunctionModifiers(
      FunctionModifiers modifiers) {
    return FunctionModifiersPB()
      ..isStatic = modifiers.isStatic
      ..isConst = modifiers.isConst
      ..isFactory = modifiers.isFactory
      ..isExternal = modifiers.isExternal;
  }

  FunctionInfoPB _convertToFunctionInfoPB(FunctionInfo info) {
    final proto = FunctionInfoPB()
      ..functionModifiers = _convertToFunctionModifiers(info.modifiers)
      ..inlinedCount = info.inlinedCount ?? 0;

    proto.returnType = info.returnType;

    proto.inferredReturnType = info.inferredReturnType;

    proto.code = info.code.map((c) => c.text).join('\n');

    proto.sideEffects = info.sideEffects;

    proto.childrenIds
        .addAll(info.closures.map(((closure) => idFor(closure).serializedId)));
    proto.parameters.addAll(info.parameters.map(_convertToParameterInfoPB));

    return proto;
  }

  FieldInfoPB _convertToFieldInfoPB(FieldInfo info) {
    final proto = FieldInfoPB()
      ..type = info.type
      ..inferredType = info.inferredType
      ..isConst = info.isConst;

    proto.code = info.code.map((c) => c.text).join('\n');

    if (info.initializer != null) {
      proto.initializerId = idFor(info.initializer!).serializedId;
    }

    proto.childrenIds
        .addAll(info.closures.map((closure) => idFor(closure).serializedId));

    return proto;
  }

  static ConstantInfoPB _convertToConstantInfoPB(ConstantInfo info) {
    return ConstantInfoPB()..code = info.code.map((c) => c.text).join('\n');
  }

  static OutputUnitInfoPB _convertToOutputUnitInfoPB(OutputUnitInfo info) {
    final proto = OutputUnitInfoPB();
    proto.imports.addAll(info.imports);
    return proto;
  }

  static TypedefInfoPB _convertToTypedefInfoPB(TypedefInfo info) {
    return TypedefInfoPB()..type = info.type;
  }

  ClosureInfoPB _convertToClosureInfoPB(ClosureInfo info) {
    return ClosureInfoPB()..functionId = idFor(info.function).serializedId;
  }

  InfoPB _convertToInfoPB(Info info) {
    final proto = InfoPB()
      ..id = idFor(info).id
      ..serializedId = idFor(info).serializedId
      ..size = info.size;

    proto.name = info.name;

    if (info.parent != null) {
      proto.parentId = idFor(info.parent!).serializedId;
    }

    if (info.coverageId != null) {
      proto.coverageId = info.coverageId!;
    }

    if (info is BasicInfo && info.outputUnit != null) {
      // TODO(lorenvs): Similar to the JSON codec, omit this for the default
      // output unit. At the moment, there is no easy way to identify which
      // output unit is the default on [OutputUnitInfo].
      proto.outputUnitId = idFor(info.outputUnit!).serializedId;
    }

    if (info is CodeInfo) {
      proto.uses.addAll(info.uses.map(_convertToDependencyInfoPB));
    }

    if (info is LibraryInfo) {
      proto.libraryInfo = _convertToLibraryInfoPB(info);
    } else if (info is ClassInfo) {
      proto.classInfo = _convertToClassInfoPB(info);
    } else if (info is ClassTypeInfo) {
      proto.classTypeInfo = _convertToClassTypeInfoPB(info);
    } else if (info is FunctionInfo) {
      proto.functionInfo = _convertToFunctionInfoPB(info);
    } else if (info is FieldInfo) {
      proto.fieldInfo = _convertToFieldInfoPB(info);
    } else if (info is ConstantInfo) {
      proto.constantInfo = _convertToConstantInfoPB(info);
    } else if (info is OutputUnitInfo) {
      proto.outputUnitInfo = _convertToOutputUnitInfoPB(info);
    } else if (info is TypedefInfo) {
      proto.typedefInfo = _convertToTypedefInfoPB(info);
    } else if (info is ClosureInfo) {
      proto.closureInfo = _convertToClosureInfoPB(info);
    }

    return proto;
  }

  ProgramInfoPB _convertToProgramInfoPB(ProgramInfo info) {
    var result = ProgramInfoPB()
      ..entrypointId = idFor(info.entrypoint).serializedId
      ..size = info.size
      ..compilationMoment = Int64(info.compilationMoment.microsecondsSinceEpoch)
      ..compilationDuration = Int64(info.compilationDuration.inMicroseconds)
      ..toProtoDuration = Int64(info.toJsonDuration.inMicroseconds)
      ..dumpInfoDuration = Int64(info.dumpInfoDuration.inMicroseconds)
      ..noSuchMethodEnabled = info.noSuchMethodEnabled
      ..isRuntimeTypeUsed = info.isRuntimeTypeUsed
      ..isIsolateUsed = info.isIsolateInUse
      ..isFunctionApplyUsed = info.isFunctionApplyUsed
      ..isMirrorsUsed = info.isMirrorsUsed
      ..minified = info.minified;

    if (info.dart2jsVersion != null) {
      result.dart2jsVersion = info.dart2jsVersion!;
    }
    return result;
  }

  Iterable<MapEntry<String, InfoPB>> _convertToAllInfosEntries<T extends Info>(
      Iterable<T> infos) sync* {
    for (final info in infos) {
      final infoProto = _convertToInfoPB(info);
      final entry = MapEntry<String, InfoPB>(infoProto.serializedId, infoProto);
      yield entry;
    }
  }

  static LibraryDeferredImportsPB _convertToLibraryDeferredImportsPB(
      String libraryUri, Map<String, dynamic> fields) {
    final proto = LibraryDeferredImportsPB()
      ..libraryUri = libraryUri
      ..libraryName = fields['name'] ?? '<unnamed>';

    Map<String, List<String>> imports = fields['imports'];
    imports.forEach((prefix, files) {
      final import = DeferredImportPB()..prefix = prefix;
      import.files.addAll(files);
      proto.imports.add(import);
    });

    return proto;
  }

  AllInfoPB _convertToAllInfoPB(AllInfo info) {
    final proto = AllInfoPB()..program = _convertToProgramInfoPB(info.program!);

    proto.allInfos.addEntries(_convertToAllInfosEntries(info.libraries));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.classes));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.classTypes));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.functions));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.fields));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.constants));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.outputUnits));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.typedefs));
    proto.allInfos.addEntries(_convertToAllInfosEntries(info.closures));

    info.deferredFiles?.forEach((libraryUri, fields) {
      proto.deferredImports
          .add(_convertToLibraryDeferredImportsPB(libraryUri, fields));
    });

    return proto;
  }
}

/// A codec for converting [AllInfo] to a protobuf format.
///
/// This codec is still experimental, and will likely crash on certain output
/// from dart2js.
class AllInfoProtoCodec extends Codec<AllInfo, AllInfoPB> {
  @override
  final Converter<AllInfo, AllInfoPB> encoder = AllInfoToProtoConverter();
  @override
  final Converter<AllInfoPB, AllInfo> decoder = ProtoToAllInfoConverter();
}

class Id {
  final InfoKind kind;
  final int id;

  Id(this.kind, this.id);

  String get serializedId => '${kindToString(kind)}/$id';
}
