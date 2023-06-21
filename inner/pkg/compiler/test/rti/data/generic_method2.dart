// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*class: A:deps=[B],explicit=[A.T*],needsArgs,test*/
class A<T> {
  @pragma('dart2js:noInline')
  foo(x) {
    return x is T;
  }
}

/*class: BB:implicit=[BB]*/
class BB {}

/*class: B:deps=[method1],implicit=[B.T],needsArgs,test*/
class B<T> implements BB {
  @pragma('dart2js:noInline')
  foo() {
    return A<T>().foo(new B());
  }
}

/*member: method1:implicit=[method1.T],needsArgs,test*/
@pragma('dart2js:noInline')
method1<T>() {
  return B<T>().foo();
}

main() {
  makeLive(method1<BB>());
  makeLive(method1<String>());
}
