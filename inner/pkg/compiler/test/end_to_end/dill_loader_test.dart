// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/names.dart';

import 'package:compiler/src/util/memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/elements/entities.dart'
    show LibraryEntity, ClassEntity;
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:compiler/src/phase/load_kernel.dart' as load_kernel;
import 'package:expect/expect.dart';
import 'package:front_end/src/api_unstable/dart2js.dart';
import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;
import 'package:kernel/target/targets.dart' show TargetFlags;

/// Test that the compiler can successfully read in .dill kernel files rather
/// than just string source files.
main() {
  asyncTest(() async {
    String filename = 'tests/corelib/list_literal_test.dart';
    Uri uri = Uri.base.resolve(filename);
    DiagnosticCollector diagnostics = DiagnosticCollector();
    OutputCollector output = OutputCollector();

    var options = CompilerOptions()
      ..target = Dart2jsTarget("dart2js", TargetFlags())
      ..nnbdMode = NnbdMode.Strong
      ..packagesFileUri = Uri.base.resolve('.dart_tool/package_config.json')
      ..additionalDills = <Uri>[
        computePlatformBinariesLocation().resolve("dart2js_platform.dill"),
      ]
      ..setExitCodeOnProblem = true
      ..verify = true;

    List<int> kernelBinary =
        serializeComponent((await kernelForProgram(uri, options))!.component!);
    var compiler = compilerFor(
        entryPoint: uri,
        memorySourceFiles: {'main.dill': kernelBinary},
        diagnosticHandler: diagnostics,
        outputProvider: output);
    load_kernel.Output result = (await load_kernel.run(load_kernel.Input(
        compiler.options,
        compiler.provider,
        compiler.reporter,
        compiler.initializedCompilerState,
        false)))!;
    compiler.frontendStrategy
        .registerLoadedLibraries(result.component, result.libraries!);

    Expect.equals(0, diagnostics.errors.length);
    Expect.equals(0, diagnostics.warnings.length);

    ElementEnvironment environment =
        compiler.frontendStrategy.elementEnvironment;
    LibraryEntity? library = environment.lookupLibrary(uri);
    Expect.isNotNull(library);
    ClassEntity? clss = environment.lookupClass(library!, 'ListLiteralTest');
    Expect.isNotNull(clss);
    var member = environment.lookupClassMember(clss!, PublicName('testMain'));
    Expect.isNotNull(member);
  });
}
