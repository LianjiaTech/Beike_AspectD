// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.
// @dart=2.9
class C {
  test() {
    use(+super);
  }
}

use(_) => null;

main() {
  new C().test();
}
