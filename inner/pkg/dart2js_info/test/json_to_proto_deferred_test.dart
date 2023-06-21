// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/proto_info_codec.dart';
import 'package:test/test.dart';

import 'test_shared.dart';

void main() {
  group('json to proto conversion with deferred files', () {
    test('hello_world_deferred', () async {
      final helloWorld = await helloWorldDeferredDumpInfo();
      final json = jsonDecode(helloWorld);
      final decoded = AllInfoJsonCodec().decode(json);
      final proto = AllInfoProtoCodec().encode(decoded);

      expect(proto.deferredImports, hasLength(1));
      final libraryImports = proto.deferredImports.first;
      expect(libraryImports.libraryUri, 'hello_world_deferred.dart');
      expect(libraryImports.libraryName, '<unnamed>');
      expect(libraryImports.imports, hasLength(1));
      final import = libraryImports.imports.first;
      expect(import.prefix, 'deferred_import');
      expect(import.files, hasLength(1));
      expect(import.files.first, 'hello_world_deferred.js_1.part.js');

      final infoMap = proto.allInfos;

      final entrypoint = infoMap[proto.program.entrypointId];
      expect(entrypoint, isNotNull);
      expect(entrypoint!.hasFunctionInfo(), isTrue);
      expect(entrypoint.outputUnitId, isNotNull);

      // The output unit of the entrypoint function should be the default
      // entrypoint, which should have no imports.
      final defaultOutputUnit = infoMap[entrypoint.outputUnitId];
      expect(defaultOutputUnit, isNotNull);
      expect(defaultOutputUnit!.hasOutputUnitInfo(), isTrue);
      expect(defaultOutputUnit.outputUnitInfo.imports, isEmpty);
    });
  });
}
