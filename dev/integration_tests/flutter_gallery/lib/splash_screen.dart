// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'splash_screen_io.dart' if (dart.library.html) 'splash_screen_web.dart' as impl;

void removeSplashScreen() {
  impl.removeSplashScreen();
}
