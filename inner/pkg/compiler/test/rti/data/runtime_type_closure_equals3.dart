// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

String method() => null;

/*spec.class: Class1:explicit=[Class1.T*],needsArgs,test*/
/*prod.class: Class1:needsArgs*/
class Class1<T> {
  Class1();

  method() {
    /*needsSignature*/
    T local1a() => null;

    /*needsSignature*/
    T local1b() => null;

    /*needsSignature*/
    T local2(T t, String s) => t;

    makeLive(local1a.runtimeType == local1b.runtimeType);
    makeLive(local1a.runtimeType == local2.runtimeType);
    makeLive(local1a.runtimeType == method.runtimeType);
  }
}

class Class2<T> {
  Class2();
}

main() {
  Class1<int>().method();
  Class2<int>();
}
