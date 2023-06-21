// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

class Class1<S> {
  Class1();

  /*member: Class1.method1a:*/
  T method1a<T>() => null;

  /*member: Class1.method1b:*/
  T method1b<T>() => null;

  /*spec.member: Class1.method2:explicit=[method2.T*],needsArgs,test*/
  T method2<T>(T t, String s) => t;
}

class Class2<T> {
  Class2();
}

main() {
  var c = Class1<int>();

  makeLive(c.method1a.runtimeType == c.method1b.runtimeType);
  makeLive(c.method1a.runtimeType == c.method2.runtimeType);
  Class2<int>();
}
