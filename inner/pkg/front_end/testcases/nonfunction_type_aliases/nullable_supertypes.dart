// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'nullable_supertypes.dart' as prefix;

class A {}
class B {}
class C {}

typedef AAlias = A?;
typedef BAlias = B?;
typedef CAlias = C?;
typedef TAlias<T> = T?;

class C1 extends AAlias {}

class C2 implements AAlias {}

class C3 = A with BAlias;

class C4 = A with B implements CAlias;

class C5 extends A with BAlias {}

mixin M1 on AAlias {}

mixin M2 on A, BAlias {}

mixin M3 on A implements BAlias {}

class D1 extends TAlias<A> {}

class D1a extends prefix.TAlias<A> {}

class D1b extends TAlias<prefix.A> {}

class D2 implements TAlias<A> {}

class D3 = A with TAlias<B>;

class D4 = A with B implements TAlias<C>;

class D5 extends A with TAlias<B> {}

mixin N1 on TAlias<A> {}

mixin N1a on prefix.TAlias<A> {}

mixin N1b on TAlias<prefix.A> {}

mixin N2 on A, TAlias<B> {}

mixin N3 on A implements TAlias<B> {}

main() {
}
