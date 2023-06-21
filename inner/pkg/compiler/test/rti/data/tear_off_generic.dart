// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: A:explicit=[A.T*],needsArgs,test*/
class A<T> {
  void m(T t) {}

  /*member: A.f:*/
  void f(int t) {}
}

main() {
  A<int>().m is void Function(int);
  A<int>().f is void Function(int);
}
