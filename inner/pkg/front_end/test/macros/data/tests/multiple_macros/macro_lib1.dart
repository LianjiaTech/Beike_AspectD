// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 declaredMacros=[Macro1],
 macrosAreAvailable
*/

import 'package:macro_builder/macro_builder.dart';

macro class Macro1 implements Macro {
  const Macro1();
}