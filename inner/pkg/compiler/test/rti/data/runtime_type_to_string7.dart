// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

class Class1 {
  Class1();
}

class Class2<T> {
  Class2();
}

/*spec.class: Class3:needsArgs*/
class Class3<T> implements Class1 {
  Class3();
}

main() {
  Class1 cls1 = Class1();
  makeLive(cls1.runtimeType.toString());
  Class2<int>();
  Class1 cls3 = Class3<int>();
  makeLive(cls3.runtimeType.toString());
}
