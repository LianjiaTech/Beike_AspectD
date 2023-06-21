// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.declaration;

import '../problems.dart' show unsupported;

abstract class Builder {
  /// Used when multiple things with the same name are declared within the same
  /// parent. Only used for top-level and class-member declarations, not for
  /// block scopes.
  Builder? next;

  Builder? get parent;

  Uri? get fileUri;

  int get charOffset;

  Builder get origin;

  String get fullNameForErrors;

  bool get hasProblem;

  bool get isConst;

  bool get isConstructor;

  bool get isFactory;

  bool get isField;

  bool get isFinal;

  bool get isGetter;

  bool get isExternal;

  /// Returns `true` if this builder is an extension declaration.
  ///
  /// For instance `B` in:
  ///
  ///    class A {}
  ///    extension B on A {}
  ///
  bool get isExtension;

  /// Returns `true` if this builder is a member of a class, mixin, or extension
  /// declaration.
  ///
  /// For instance `A.constructor`, `method1a`, `method1b`, `method2a`,
  /// `method2b`, `method3a`, and `method3b` in:
  ///
  ///     class A {
  ///       A.constructor();
  ///       method1a() {}
  ///       static method1b() {}
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {}
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {}
  ///     }
  ///
  bool get isDeclarationMember;

  /// Returns `true` if this builder is a member of a class or mixin
  /// declaration.
  ///
  /// For instance `A.constructor`, `method1a`, `method1b`, `method2a` and
  /// `method2b` in:
  ///
  ///     class A {
  ///       A.constructor();
  ///       method1a() {}
  ///       static method1b() {}
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {}
  ///     }
  ///     extends C on A {
  ///       method3a() {}        // Not a class member.
  ///       static method3b() {} // Not a class member.
  ///     }
  ///
  bool get isClassMember;

  /// Returns `true` if this builder is a member of an extension declaration.
  ///
  /// For instance `method3a` and `method3b` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an extension member.
  ///       method1a() {}        // Not an extension member.
  ///       static method1b() {} // Not an extension member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an extension member.
  ///       static method2b() {} // Not an extension member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {}
  ///     }
  ///
  bool get isExtensionMember;

  /// Returns `true` if this builder is a member of an inline class declaration.
  ///
  /// For instance `method3a` and `method3b` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an inline class member.
  ///       method1a() {}        // Not an inline class member.
  ///       static method1b() {} // Not an inline class member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an inline class member.
  ///       static method2b() {} // Not an inline class member.
  ///     }
  ///     inline class C {
  ///       final A it;
  ///       C(this.t);
  ///       method3a() {}
  ///       static method3b() {}
  ///     }
  ///
  bool get isInlineClassMember;

  /// Returns `true` if this builder is an instance member of a class, mixin, or
  /// extension declaration.
  ///
  /// For instance `method1a`, `method2a`, and `method3a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not a declaration instance member.
  ///       method1a() {}
  ///       static method1b() {} // Not a declaration instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {} // Not a declaration instance member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {} // Not a declaration instance member.
  ///     }
  ///
  bool get isDeclarationInstanceMember;

  /// Returns `true` if this builder is an instance member of a class or mixin
  /// extension declaration.
  ///
  /// For instance `method1a` and `method2a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not a class instance member.
  ///       method1a() {}
  ///       static method1b() {} // Not a class instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}
  ///       static method2b() {} // Not a class instance member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}        // Not a class instance member.
  ///       static method3b() {} // Not a class instance member.
  ///     }
  ///
  bool get isClassInstanceMember;

  /// Returns `true` if this builder is an instance member of an extension
  /// declaration.
  ///
  /// For instance `method3a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an extension instance member.
  ///       method1a() {}        // Not an extension instance member.
  ///       static method1b() {} // Not an extension instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an extension instance member.
  ///       static method2b() {} // Not an extension instance member.
  ///     }
  ///     extends C on A {
  ///       method3a() {}
  ///       static method3b() {} // Not an extension instance member.
  ///     }
  ///
  bool get isExtensionInstanceMember;

  /// Returns `true` if this builder is an instance member of an extension
  /// declaration.
  ///
  /// For instance `method3a` in:
  ///
  ///     class A {
  ///       A.constructor();     // Not an inline class instance member.
  ///       method1a() {}        // Not an inline class instance member.
  ///       static method1b() {} // Not an inline class instance member.
  ///     }
  ///     mixin B {
  ///       method2a() {}        // Not an inline class instance member.
  ///       static method2b() {} // Not an inline class instance member.
  ///     }
  ///     inline class C {
  ///       final A it;
  ///       A(this.is);          // Not an inline class instance member.
  ///       method3a() {}
  ///       static method3b() {} // Not an inline class instance member.
  ///     }
  ///
  bool get isInlineClassInstanceMember;

  bool get isLocal;

  bool get isPatch;

  bool get isRegularMethod;

  bool get isOperator;

  bool get isSetter;

  bool get isStatic;

  bool get isSynthetic;

  bool get isTopLevel;

  bool get isTypeDeclaration;

  bool get isTypeVariable;

  /// Applies [patch] to this declaration.
  void applyPatch(Builder patch);

  /// Return `true` if this builder is a duplicate of another with the same
  /// name. This is `false` for the builder first declared amongst duplicates.
  bool get isDuplicate;
}

abstract class BuilderImpl implements Builder {
  @override
  Builder? next;

  BuilderImpl();

  @override
  Builder get origin => this;

  @override
  bool get hasProblem => false;

  @override
  bool get isConst => false;

  @override
  bool get isConstructor => false;

  @override
  bool get isFactory => false;

  @override
  bool get isField => false;

  @override
  bool get isFinal => false;

  @override
  bool get isGetter => false;

  @override
  bool get isExtension => false;

  @override
  bool get isDeclarationMember => false;

  @override
  bool get isClassMember => false;

  @override
  bool get isExtensionMember => false;

  @override
  bool get isInlineClassMember => false;

  @override
  bool get isDeclarationInstanceMember => false;

  @override
  bool get isClassInstanceMember => false;

  @override
  bool get isExtensionInstanceMember => false;

  @override
  bool get isInlineClassInstanceMember => false;

  @override
  bool get isLocal => false;

  @override
  bool get isPatch => this != origin;

  @override
  bool get isRegularMethod => false;

  @override
  bool get isOperator => false;

  @override
  bool get isSetter => false;

  @override
  bool get isStatic => false;

  @override
  bool get isExternal => false;

  @override
  bool get isSynthetic => false;

  @override
  bool get isTopLevel => false;

  @override
  bool get isTypeDeclaration => false;

  @override
  bool get isTypeVariable => false;

  @override
  void applyPatch(Builder patch) {
    unsupported("${runtimeType}.applyPatch", charOffset, fileUri);
  }

  @override
  bool get isDuplicate => next != null;
}

extension BuilderExtension on Builder {
  /// Returns the 'duplicate index' for this builder, which is the number of
  /// builders declared prior this.
  ///
  /// For a non-duplicate builder, this is 0.
  int get duplicateIndex {
    if (next != null) {
      int count = 0;
      Builder? current = next;
      while (current != null) {
        count++;
        current = current.next;
      }
      return count;
    }
    return 0;
  }
}
