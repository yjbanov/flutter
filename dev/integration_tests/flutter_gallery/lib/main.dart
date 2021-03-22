// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Thanks for checking out Flutter!
// Like what you see? Tweet us @FlutterDev

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'gallery/app.dart';

import 'splash_screen.dart';

void main() {
  runApp(const GalleryApp());
  SchedulerBinding.instance!.addPostFrameCallback((Duration timeStamp) {
    removeSplashScreen();
  });
}
