// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*member: method1a:*/
T method1a<T>() => null;

/*member: method1b:*/
T method1b<T>() => null;

/*spec.member: method2:explicit=[method2.T*],needsArgs,test*/
T method2<T>(T t, String s) => t;

class Class<T> {
  Class();
}

main() {
  makeLive(method1a.runtimeType == method1b.runtimeType);
  makeLive(method1a.runtimeType == method2.runtimeType);
  Class<int>();
}
