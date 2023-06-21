// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*spec.class: Class1:needsArgs*/
class Class1<T> {
  Class1();

  /*spec.member: Class1.method:needsSignature*/
  T method() => null;
}

class Class2<T> {
  Class2();
}

main() {
  Class1<int> cls1 = Class1<int>();
  makeLive(cls1.method.runtimeType.toString());
  Class2<int>();
}
