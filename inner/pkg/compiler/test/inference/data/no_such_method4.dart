// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:[exact=A]*/
class A {
  // We may ignore this for type inference because it forwards to a default
  // noSuchMethod implementation, which always throws an exception.
  noSuchMethod(im) => super.noSuchMethod(im);
}

/*member: B.:[exact=B]*/
class B extends A {
  /*member: B.foo:Dictionary([exact=JsLinkedHashMap], key: [empty], value: [null], map: {})*/ foo() =>
      {};
}

/*member: C.:[exact=C]*/
class C extends B {
  /*member: C.foo:Dictionary([exact=JsLinkedHashMap], key: [empty], value: [null], map: {})*/ foo() =>
      {};
}

/*member: a:[null|subclass=B]*/
dynamic a = [new B(), C()]
    /*Container([exact=JSExtendableArray], element: [subclass=B], length: 2)*/
    [0];

/*member: test1:[empty]*/
test1() {
  dynamic e = A();
  return e. /*invoke: [exact=A]*/ foo();
}

/*member: test2:Dictionary([exact=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test2() => a. /*invoke: [null|subclass=B]*/ foo();

/*member: test3:Dictionary([exact=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test3() => B(). /*invoke: [exact=B]*/ foo();

/*member: test4:Dictionary([exact=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test4() => C(). /*invoke: [exact=C]*/ foo();

/*member: test5:Dictionary([exact=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test5() {
  dynamic e = (a ? A() : B());
  return e. /*invoke: [subclass=A]*/ foo();
}

/*member: test6:Dictionary([exact=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test6() => (a ? B() : C()). /*invoke: [subclass=B]*/ foo();

/*member: main:[null]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
