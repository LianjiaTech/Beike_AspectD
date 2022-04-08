// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super<T> {
  void method1(num a) {}
  void method2(int b) {}
  void method3(num a, int b) {}
  void method4({required num a}) {}
  void method5({required int b}) {}
  //void method6({required num a, required int b}) {}
  void method7(Iterable<T> a) {}
  void method8(List<T> b) {}
  void method9(Iterable<T> a, List<T> b) {}
  void method10({required Iterable<T> a}) {}
  void method11({required List<T> b}) {}
  //void method12({required Iterable<T> a, required List<T> b}) {}

  void set setter1(num a) {}
  //void set setter2(int a) {}
  void set setter3(Iterable<T> a) {}
  //void set setter4(List<T> a) {}
}

abstract class Interface<T> {
  void method2(covariant num b) {}
  void method3(num a, covariant num b) {}
  void method5({required int b}) {}
  //void method6({required num a, required covariant num b}) {}
  void method8(covariant Iterable<T> b) {}
  void method9(Iterable<T> a, covariant Iterable<T> b) {}
  void method11({required List<T> b}) {}
  //void method12({required Iterable<T> a, required covariant Iterable<T> b}) {}
  //void set setter2(covariant num a) {}
  //void set setter4(covariant Iterable<T> a) {}
}

class Class<T> extends Super<T> implements Interface<T> {
  void method1(covariant int a);
  void method2(num b);
  void method3(covariant int a, num b);
  void method7(covariant List<T> a);
  void method8(Iterable<T> b);
  void method9(covariant List<T> a, Iterable<T> b);
  void set setter1(covariant int a);
  //void set setter2(num a);
  void set setter3(covariant List<T> a);
  //void set setter4(Iterable<T> a);
}

class Class1<T> implements Class<T> {
  void method1(double a) {} // error
  void method2(double b) {} // error
  void method3(double a, double b) {} // error
  void method4({required double a}) {} // error
  void method5({required double b}) {} // error
  //void method6({required double a, required double b}) {} // error
  void method7(Set<T> a) {} // error
  void method8(Set<T> b) {} // error
  void method9(Set<T> a, Set<T> b) {} // error
  void method10({required Set<T> a}) {} // error
  void method11({required Set<T> b}) {} // error
  //void method12({required Set<T> a, required Set<T> b}) {} // error
  void set setter1(double a) {} // error
  //void set setter2(double a) {} // error
  void set setter3(Set<T> a) {} // error
  //void set setter4(Set<T> a) {} // error
}

abstract class Interface2<T> {
  void method1(int a);
  void method2(int b);
  void method3(int a, int b);
  void method7(List<T> a);
  void method8(List<T> b);
  void method9(List<T> a, List<T> b);
  void set setter1(int a);
  //void set setter2(int a);
  void set setter3(List<T> a);
  //void set setter4(List<T> a);
}

abstract class Class2<T> implements Class<T>, Interface2<T> {}

main() {}