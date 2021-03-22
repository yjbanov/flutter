// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:flutter/cupertino.dart';

void removeSplashScreen() {
  final html.Element? splashScreenElement = html.document.querySelector('#splash-screen');
  final html.Element? flutterGlassPane = html.document.querySelector('flt-glass-pane');
  if (splashScreenElement == null || flutterGlassPane == null) {
    return;
  }
  flutterGlassPane.style.opacity = '0';

  const Duration fadeInDuration = Duration(seconds: 1);
  Duration? fadeInStart;
  void fadeIn(num rawTimestamp) {
    final Duration timestamp = Duration(microseconds: (1000 * rawTimestamp).toInt());
    fadeInStart ??= timestamp;
    final Duration duration = timestamp - fadeInStart!;
    double t = 0;
    if (duration > fadeInDuration) {
      splashScreenElement.remove();
      return;
    }

    t = duration.inMicroseconds / fadeInDuration.inMicroseconds;
    flutterGlassPane.style.opacity = '${Curves.easeInOut.transform(t)}';
    html.window.requestAnimationFrame(fadeIn);
  }

  html.window.requestAnimationFrame(fadeIn);
}
