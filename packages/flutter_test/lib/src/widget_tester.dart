// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'element_tree_tester.dart';

void testWidgets(callback(WidgetTester widgetTester)) {
  testElementTree((ElementTreeTester elementTreeTester) {
    callback(new WidgetTester._(elementTreeTester));
  });
}

class WidgetTester {
  WidgetTester._(this.elementTreeTester);

  final ElementTreeTester elementTreeTester;

  void pumpWidget(Widget widget, [ Duration duration, EnginePhase phase ]) {
    elementTreeTester.pumpWidget(widget, duration, phase);
  }

  void pump([ Duration duration, EnginePhase phase ]) {
    elementTreeTester.pump(duration, phase);
  }

  /// Artificially calls dispatchLocaleChanged on the Widget binding,
  /// then flushes microtasks.
  void setLocale(String languageCode, String countryCode) {
    elementTreeTester.setLocale(languageCode, countryCode);
  }

  void dispatchEvent(PointerEvent event, HitTestResult result) {
    elementTreeTester.dispatchEvent(event, result);
  }

  /// Returns the exception most recently caught by the Flutter framework.
  ///
  /// Call this if you expect an exception during a test. If an exception is
  /// thrown and this is not called, then the exception is rethrown when
  /// the [testWidgets] call completes.
  ///
  /// If two exceptions are thrown in a row without the first one being
  /// acknowledged with a call to this method, then when the second exception is
  /// thrown, they are both dumped to the console and then the second is
  /// rethrown from the exception handler. This will likely result in the
  /// framework entering a highly unstable state and everything collapsing.
  ///
  /// It's safe to call this when there's no pending exception; it will return
  /// null in that case.
  dynamic takeException() {
    return elementTreeTester.takeException();
  }

  void flushMicrotasks() {
    elementTreeTester.async.flushMicrotasks();
  }

  bool exists(Finder finder) => finder.find(this.elementTreeTester) != null;
}

const CommonFinders find = const CommonFinders();

class CommonFinders {
  const CommonFinders();

  Finder text(String text) => new _TextFinder(text);
}

abstract class Finder {
  Element find(ElementTreeTester tester);
}

class _TextFinder {
  _TextFinder(this.text);

  final String text;

  @override
  Element find(ElementTreeTester tester) {
    return tester.findText(text);
  }
}
