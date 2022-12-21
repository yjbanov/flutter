// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'my_app.dart' if (dart.library.html) 'my_web_app.dart';

void main() => startApp();

/// A 2x2 grid of cells of known colors filling the view.
// This is used by tests. Not meant to be reachable from main.
// ignore: unreachable_from_main
Widget makeTestGrid() {
  Widget makeCell(int column, int row, Size screenSize, Color color) {
    final double halfHeight = screenSize.height / 2;
    final double halfWidth = screenSize.width / 2;
    return Positioned(
      left: halfWidth * column,
      top: halfHeight * row,
      child: Container(
        height: halfHeight,
        width: halfWidth,
        color: color,
      ),
    );
  }

  return MaterialApp(
    home: Builder(
      builder: (BuildContext context) {
        final Size screenSize = MediaQuery.of(context).size;
        return Stack(
          children: <Widget>[
            makeCell(0, 0, screenSize, const Color(0xFF000000)),
            makeCell(0, 1, screenSize, const Color(0xFFFFFFFF)),
            makeCell(1, 0, screenSize, const Color(0xFF000000)),
            makeCell(1, 1, screenSize, const Color(0xFFFFFFFF)),
          ],
        );
      }
    ),
  );
}
