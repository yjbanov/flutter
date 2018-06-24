// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Built-in types and core primitives for a Flutter application.
///
/// To use, import `dart:ui`.
///
/// This library exposes the lowest-level services that Flutter frameworks use
/// to bootstrap applications, such as classes for driving the input, graphics
/// text, layout, and rendering subsystems.
library dart.web.ui;

import 'dart:async';
import 'dart:collection' as collection;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate' show SendPort;
import 'dart:math' as math;
import 'dart:typed_data';

part 'src/ui/compositing.dart';
part 'src/ui/geometry.dart';
part 'src/ui/hash_codes.dart';
part 'src/ui/hooks.dart';
part 'src/ui/isolate_name_server.dart';
part 'src/ui/lerp.dart';
part 'src/ui/natives.dart';
part 'src/ui/painting.dart';
part 'src/ui/pointer.dart';
part 'src/ui/semantics.dart';
part 'src/ui/text.dart';
part 'src/ui/window.dart';

/// Indicates that a `dart:ui` function or method that's backed by a native
/// C++ function is not implemented in the web engine.
class UnimplementedNativeFunctionError extends UnimplementedError { }
