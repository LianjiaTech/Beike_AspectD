// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensures that closures are in the output unit of their enclosing element.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_api.dart' as api;
import 'package:expect/expect.dart';

import 'package:compiler/src/util/memory_compiler.dart';

void main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}

runTest() async {
  OutputCollector collector = OutputCollector();
  await runCompiler(memorySourceFiles: sources, outputProvider: collector);
  String mainOutput = collector.getOutput("", api.OutputType.js)!;
  String deferredOutput = collector.getOutput("out_1", api.OutputType.jsPart)!;

  Expect.isTrue(mainOutput.contains("other_method_name() {"));
  Expect.isFalse(mainOutput.contains("unique_method_name() {"));
  Expect.isFalse(mainOutput.contains("unique_method_name_closure() {"));
  Expect.isFalse(mainOutput.contains("unique-string"));

  Expect.isFalse(deferredOutput.contains("other_method_name() {"));
  Expect.isTrue(deferredOutput.contains("unique_method_name() {"));
  Expect.isTrue(deferredOutput.contains("unique_method_name_closure() {"));
  Expect.isTrue(deferredOutput.contains("unique-string"));
}

// Make sure that deferred constants are not inlined into the main hunk.
const Map<String, String> sources = const {
  "main.dart": """
    import 'lib.dart' deferred as lib;

    main() async {
      await (lib.loadLibrary)();
      lib.unique_method_name();
      other_method_name();
    }
    other_method_name() { throw "hi"; }""",
  "lib.dart": """
    library deferred;

    unique_method_name() => (() => print("unique-string"))();
    """
};
