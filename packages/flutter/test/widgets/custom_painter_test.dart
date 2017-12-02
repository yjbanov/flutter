// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  group(CustomPainter, () {
    setUp(() {
      debugResetSemanticsIdCounter();
    });

    _defineTests();
  });
}

void _defineTests() {
  testWidgets('builds no semantics by default', (WidgetTester tester) async {
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    await tester.pumpWidget(new CustomPaint(
      painter: new _PainterWithoutSemantics(),
    ));

    expect(semanticsTester, hasSemantics(
      new TestSemantics.root(
        children: const <TestSemantics>[],
      ),
    ));

    semanticsTester.dispose();
  });

  testWidgets('provides foreground semantics', (WidgetTester tester) async {
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    await tester.pumpWidget(new CustomPaint(
      foregroundPainter: new _PainterWithSemantics(
        semantics: new CustomPainterSemantics(
          rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
          properties: const SemanticsProperties(
            label: 'foreground',
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    ));

    expect(semanticsTester, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                id: 2,
                label: 'foreground',
                rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
              ),
            ],
          ),
        ],
      ),
    ));

    semanticsTester.dispose();
  });

  testWidgets('provides background semantics', (WidgetTester tester) async {
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    await tester.pumpWidget(new CustomPaint(
      painter: new _PainterWithSemantics(
        semantics: new CustomPainterSemantics(
          rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
          properties: const SemanticsProperties(
            label: 'background',
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    ));

    expect(semanticsTester, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                id: 2,
                label: 'background',
                rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
              ),
            ],
          ),
        ],
      ),
    ));

    semanticsTester.dispose();
  });

  testWidgets('combines background, child and foreground semantics', (WidgetTester tester) async {
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    await tester.pumpWidget(new CustomPaint(
      painter: new _PainterWithSemantics(
        semantics: new CustomPainterSemantics(
          rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
          properties: const SemanticsProperties(
            label: 'background',
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
      child: new Semantics(
        container: true,
        child: const Text('Hello', textDirection: TextDirection.ltr),
      ),
      foregroundPainter: new _PainterWithSemantics(
        semantics: new CustomPainterSemantics(
          rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
          properties: const SemanticsProperties(
            label: 'foreground',
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    ));

    expect(semanticsTester, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                id: 3,
                label: 'background',
                rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
              ),
              new TestSemantics(
                id: 2,
                label: 'Hello',
                rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
              ),
              new TestSemantics(
                id: 4,
                label: 'foreground',
                rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
              ),
            ],
          ),
        ],
      ),
    ));

    semanticsTester.dispose();
  });

  testWidgets('applies $SemanticsProperties', (WidgetTester tester) async {
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    await tester.pumpWidget(new CustomPaint(
      painter: new _PainterWithSemantics(
        semantics: new CustomPainterSemantics(
          key: const ValueKey<int>(1),
          rect: new Rect.fromLTRB(1.0, 2.0, 3.0, 4.0),
          properties: const SemanticsProperties(
            checked: false,
            selected: false,
            button: false,
            label: 'label-before',
            value: 'value-before',
            increasedValue: 'increase-before',
            decreasedValue: 'decrease-before',
            hint: 'hint-before',
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    ));

    expect(semanticsTester, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                rect: new Rect.fromLTRB(1.0, 2.0, 3.0, 4.0),
                id: 2,
                flags: 1,
                label: 'label-before',
                value: 'value-before',
                increasedValue: 'increase-before',
                decreasedValue: 'decrease-before',
                hint: 'hint-before',
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    ));

    await tester.pumpWidget(new CustomPaint(
      painter: new _PainterWithSemantics(
        semantics: new CustomPainterSemantics(
          key: const ValueKey<int>(1),
          rect: new Rect.fromLTRB(5.0, 6.0, 7.0, 8.0),
          properties: new SemanticsProperties(
            checked: true,
            selected: true,
            button: true,
            label: 'label-after',
            value: 'value-after',
            increasedValue: 'increase-after',
            decreasedValue: 'decrease-after',
            hint: 'hint-after',
            textDirection: TextDirection.ltr,
            onScrollDown: () {},
            onLongPress: () {},
            onDecrease: () {},
            onIncrease: () {},
            onScrollLeft: () {},
            onScrollRight: () {},
            onScrollUp: () {},
            onTap: () {},
          ),
        ),
      ),
    ));

    expect(semanticsTester, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: TestSemantics.fullScreen,
            children: <TestSemantics>[
              new TestSemantics(
                rect: new Rect.fromLTRB(5.0, 6.0, 7.0, 8.0),
                actions: 255,
                id: 2,
                flags: 15,
                label: 'label-after',
                value: 'value-after',
                increasedValue: 'increase-after',
                decreasedValue: 'decrease-after',
                hint: 'hint-after',
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ],
      ),
    ));

    semanticsTester.dispose();
  });

  group('diffing', () {
    testWidgets('complains about duplicate keys', (WidgetTester tester) async {
      final SemanticsTester semanticsTester = new SemanticsTester(tester);
      await tester.pumpWidget(new CustomPaint(
        painter: new _SemanticsDiffTest(<String>[
          'a-k',
          'a-k',
        ]),
      ));
      expect(tester.takeException(), isFlutterError);
      semanticsTester.dispose();
    });

    testDiff('adds one item to an empty list', (_DiffTester tester) async {
      await tester.diff(
        from: <String>[],
        to: <String>['a'],
      );
    });

    testDiff('removes the last item from the list', (_DiffTester tester) async {
      await tester.diff(
        from: <String>['a'],
        to: <String>[],
      );
    });

    testDiff('appends one item at the end of a non-empty list', (_DiffTester tester) async {
      await tester.diff(
        from: <String>['a'],
        to: <String>['a', 'b'],
      );
    });

    testDiff('prepends one item at the beginning of a non-empty list', (_DiffTester tester) async {
      await tester.diff(
        from: <String>['b'],
        to: <String>['a', 'b'],
      );
    });

    testDiff('inserts one item in the middle of a list', (_DiffTester tester) async {
      await tester.diff(
        from: <String>[
          'a-k',
          'c-k',
        ],
        to: <String>[
          'a-k',
          'b-k',
          'c-k',
        ],
      );
    });

    testDiff('removes one item from the middle of a list', (_DiffTester tester) async {
      await tester.diff(
        from: <String>[
          'a-k',
          'b-k',
          'c-k',
        ],
        to: <String>[
          'a-k',
          'c-k',
        ],
      );
    });

    testDiff('swaps two items', (_DiffTester tester) async {
      await tester.diff(
        from: <String>[
          'a-k',
          'b-k',
        ],
        to: <String>[
          'b-k',
          'a-k',
        ],
      );
    });

    testDiff('finds and moved one keyed item', (_DiffTester tester) async {
      await tester.diff(
        from: <String>[
          'a-k',
          'b',
          'c',
        ],
        to: <String>[
          'b',
          'c',
          'a-k',
        ],
      );
    });
  });
}

void testDiff(String description, Future<Null> Function(_DiffTester tester) testFunction) {
  testWidgets(description, (WidgetTester tester) async {
    await testFunction(new _DiffTester(tester));
  });
}

class _DiffTester {
  _DiffTester(this.tester);

  final WidgetTester tester;

  /// Creates an initial semantics list using the `from` list, then updates the
  /// list to the `to` list. This causes [RenderCustomPaint] to diff the two
  /// lists and apply the changes. This method asserts the the changes were
  /// applied correctly, specifically:
  ///
  /// - checks that initial and final configurations are in the desired states.
  /// - checks that keyed nodes have stable IDs.
  Future<Null> diff({List<String> from, List<String> to}) async {
    final SemanticsTester semanticsTester = new SemanticsTester(tester);

    TestSemantics createExpectations(List<String> labels) {
      final List<TestSemantics> children = <TestSemantics>[];
      for (String label in labels) {
        children.add(
          new TestSemantics(
            rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
            label: label,
          ),
        );
      }

      return new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            rect: TestSemantics.fullScreen,
            children: children,
          ),
        ],
      );
    }

    await tester.pumpWidget(new CustomPaint(
      painter: new _SemanticsDiffTest(from),
    ));
    expect(semanticsTester, hasSemantics(createExpectations(from), ignoreId: true));

    SemanticsNode root = RendererBinding.instance?.renderView?.debugSemantics;
    final Map<Key, int> idAssignments = <Key, int>{};
    root.visitChildren((SemanticsNode firstChild) {
      firstChild.visitChildren((SemanticsNode node) {
        if (node.key != null) {
          idAssignments[node.key] = node.id;
        }
        return true;
      });
      return true;
    });

    await tester.pumpWidget(new CustomPaint(
      painter: new _SemanticsDiffTest(to),
    ));
    await tester.pumpAndSettle();
    expect(semanticsTester, hasSemantics(createExpectations(to), ignoreId: true));

    root = RendererBinding.instance?.renderView?.debugSemantics;
    root.visitChildren((SemanticsNode firstChild) {
      firstChild.visitChildren((SemanticsNode node) {
        if (node.key != null && idAssignments[node.key] != null) {
          expect(idAssignments[node.key], node.id, reason:
            'Node with key ${node.key} was previously assigned id ${idAssignments[node.key]}. '
            'After diffing the child list, its id changed to ${node.id}. Ids must be stable.');
        }
        return true;
      });
      return true;
    });

    semanticsTester.dispose();
  }
}

class _SemanticsDiffTest extends CustomPainter {
  _SemanticsDiffTest(this.data);

  final List<String> data;

  @override
  void paint(Canvas canvas, Size size) {
    // We don't test painting.
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => buildSemantics;

  List<CustomPainterSemantics> buildSemantics(Size size) {
    final List<CustomPainterSemantics> semantics = <CustomPainterSemantics>[];
    for (String label in data) {
      Key key;
      if (label.endsWith('-k')) {
        key = new ValueKey<String>(label);
      }
      semantics.add(
        new CustomPainterSemantics(
          rect: new Rect.fromLTRB(1.0, 1.0, 2.0, 2.0),
          key: key,
          properties: new SemanticsProperties(
            label: label,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
    return semantics;
  }

  @override
  bool shouldRepaint(_SemanticsDiffTest oldPainter) => true;
}

class _PainterWithSemantics extends CustomPainter {
  _PainterWithSemantics({ this.semantics });

  final CustomPainterSemantics semantics;

  @override
  void paint(Canvas canvas, Size size) {
    // We don't test painting.
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => buildSemantics;

  List<CustomPainterSemantics> buildSemantics(Size size) {
    return <CustomPainterSemantics>[semantics];
  }

  @override
  bool shouldRepaint(_PainterWithSemantics oldPainter) => true;
}

class _PainterWithoutSemantics extends CustomPainter {
  _PainterWithoutSemantics();

  @override
  void paint(Canvas canvas, Size size) {
    // We don't test painting.
  }

  @override
  bool shouldRepaint(_PainterWithSemantics oldPainter) => true;
}
