// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstMapKeyExpressionTypeImplementsEqualsTest);
    defineReflectiveTests(
      ConstMapKeyExpressionTypeImplementsEqualsWithUIAsCodeTest,
    );
  });
}

@reflectiveTest
class ConstMapKeyExpressionTypeImplementsEqualsTest
    extends DriverResolutionTest {
  test_abstract() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
  bool operator==(Object other);
}

main() {
  const {const A(): 0};
}
''');
  }

  test_constField() async {
    await assertErrorsInCode(r'''
main() {
  const {double.INFINITY: 0};
}
''', [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_direct() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const {const A() : 0};
}
''', [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_dynamic() async {
    // Note: static type of B.a is "dynamic", but actual type of the const
    // object is A.  We need to make sure we examine the actual type when
    // deciding whether there is a problem with operator==.
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

class B {
  static const a = const A();
}

main() {
  const {B.a : 0};
}
''', [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_factory() async {
    await assertErrorsInCode(r'''
class A {
  const factory A() = B;
}

class B implements A {
  const B();
  operator ==(o) => true;
}

main() {
  const {const A(): 42};
}
''', [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_super() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

class B extends A {
  const B();
}

main() {
  const {const B() : 0};
}
''', [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
  }
}

@reflectiveTest
class ConstMapKeyExpressionTypeImplementsEqualsWithUIAsCodeTest
    extends ConstMapKeyExpressionTypeImplementsEqualsTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = ['control-flow-collections', 'spread-collections'];
}
