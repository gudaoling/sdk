// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonHintCodeTest);
  });
}

@reflectiveTest
class NonHintCodeTest extends ResolverTestCase {
  test_async_future_object_without_return() async {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_1() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message, var dynamic_) {
  if (message is Function) {
    message = dynamic_;
  }
  int s = message;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_3() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message) {
  var dynamic_;
  if (message is Function) {
    message = dynamic_;
  } else {
    return;
  }
  int s = message;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_4() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message) {
  if (message is Function) {
    message = '';
  } else {
    return;
  }
  String s = message;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_propagatedFieldType() async {
    Source source = addSource(r'''
class A { }
class X<T> {
  final x = new List<T>();
}
class Z {
  final X<A> y = new X<A>();
  foo() {
    y.x.add(new A());
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_proxy_annotation_prefixed() async {
    Source source = addSource(r'''
library L;
@proxy
class A {}
f(var a) {
  a = new A();
  a.m();
  var x = a.g;
  a.s = 1;
  var y = a + a;
  a++;
  ++a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_prefixed2() async {
    Source source = addSource(r'''
library L;
@proxy
class A {}
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_prefixed3() async {
    Source source = addSource(r'''
library L;
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}
@proxy
class A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_assignmentExpression_inSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a, var a2) {
  a = new A();
  a2 = new A();
  a += a2;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_dynamic() async {
    Source source = addSource(r'''
class D<T extends dynamic> {
  fieldAccess(T t) => t.abc;
  methodAccess(T t) => t.xyz(1, 2, 'three');
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_unionType_all() async {
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m() => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedMethod_unionType_some() async {
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m(0);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }
}

class PubSuggestionCodeTest extends ResolverTestCase {
  // TODO(brianwilkerson) The tests in this class are not being run, and all but
  //  the first would fail. We should implement these checks and enable the
  //  tests.
  test_import_package() async {
    Source source = addSource("import 'package:somepackage/other.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_import_packageWithDotDot() async {
    Source source = addSource("import 'package:somepackage/../other.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
      HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
    ]);
  }

  test_import_packageWithLeadingDotDot() async {
    Source source = addSource("import 'package:../other.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.URI_DOES_NOT_EXIST,
      HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
    ]);
  }

  test_import_referenceIntoLibDirectory() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE]);
  }

  test_import_referenceIntoLibDirectory_no_pubspec() async {
    addNamedSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_referenceOutOfLibDirectory() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE]);
  }

  test_import_referenceOutOfLibDirectory_no_pubspec() async {
    addNamedSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_valid_inside_lib1() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import 'other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_valid_inside_lib2() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/lib/bar/other.dart", "");
    Source source = addNamedSource(
        "/myproj/lib/foo/test.dart", "import '../bar/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_import_valid_outside_lib() async {
    addNamedSource("/myproj/pubspec.yaml", "");
    addNamedSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib2/test.dart", "import '../web/other.dart';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }
}
