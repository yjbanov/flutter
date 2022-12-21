// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:image/image.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  await integrationDriver(
    driver: driver,
    onScreenshot: (
      String screenshotName,
      List<int> screenshotBytes, [
      Map<String, Object?>? args,
    ]) async {
      if (screenshotName == 'platform_name_2') {
        final Image screenshot = decodeImage(screenshotBytes)!;
        final int topLeft = screenshot.getPixel(1, 1);
        final int bottomLeft = screenshot.getPixel(1, screenshot.height - 1);
        final int topRight = screenshot.getPixel(screenshot.width - 1, 1);
        final int bottomRight = screenshot.getPixel(screenshot.width - 1, screenshot.height - 1);
        final bool colorsMatch =
          topLeft == 0xFF000000 &&
          bottomLeft == 0xFFFFFFFF &&
          topRight == 0xFF000000 &&
          bottomRight == 0xFFFFFFFF;
        if (!colorsMatch) {
          return false;
        }
      }

      // Here is an example of using an argument that was passed in via the
      // optional 'args' Map.
      if (args != null) {
        final String? someArgumentValue = args['someArgumentKey'] as String?;
        return someArgumentValue != null;
      }
      return true;
    },
  );
}
