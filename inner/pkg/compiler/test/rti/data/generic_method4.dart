// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*class: A:deps=[C.method2],explicit=[A.T*],needsArgs,test*/
class A<T> {
  @pragma('dart2js:noInline')
  foo(x) {
    return x is T;
  }
}

/*class: BB:implicit=[BB]*/
class BB {}

/*class: B:deps=[C.method1],implicit=[B.T],needsArgs,test*/
class B<T> implements BB {
  @pragma('dart2js:noInline')
  foo(c) {
    return c.method2<T>().foo(new B());
  }
}

class C {
  /*member: C.method1:implicit=[method1.T],needsArgs,selectors=[Selector(call, method1, arity=0, types=1)],test*/
  @pragma('dart2js:noInline')
  method1<T>() {
    return B<T>().foo(this);
  }

  /*member: C.method2:deps=[B],implicit=[method2.T],needsArgs,selectors=[Selector(call, method2, arity=0, types=1)],test*/
  @pragma('dart2js:noInline')
  method2<T>() => A<T>();
}

main() {
  var c = C();
  makeLive(c.method1<BB>());
  makeLive(c.method1<String>());
}
