// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:meta/meta.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Minimum number of samples collected by a benchmark irrespective of noise
/// levels.
const int _kMinSampleCount = 50;

/// Maximum number of samples collected by a benchmark irrespective of noise
/// levels.
///
/// If the noise doesn't settle down before we reach the max we'll report noisy
/// results assuming the benchmarks is simply always noisy.
const int _kMaxSampleCount = 10 * _kMinSampleCount;

/// The number of samples used to extract metrics, such as noise, means,
/// max/min values.
const int _kMeasuredSampleCount = 10;

/// Maximum tolerated noise level.
///
/// A benchmark continues running until a noise level below this threshold is
/// reached.
const double _kNoiseThreshold = 0.05; // 5%

/// Measures the amount of time [action] takes.
Duration timeAction(VoidCallback action) {
  final Stopwatch stopwatch = Stopwatch()..start();
  action();
  stopwatch.stop();
  return stopwatch.elapsed;
}

/// A recorder for benchmarking interactions with the engine without the
/// framework by directly exercising [SceneBuilder].
///
/// To implement a benchmark, extend this class and implement [onDrawFrame].
///
/// Example:
///
/// ```
/// class BenchDrawCircle extends RawRecorder {
///   BenchDrawCircle() : super(name: benchmarkName);
///
///   static const String benchmarkName = 'draw_circle';
///
///   @override
///   void onDrawFrame(SceneBuilder sceneBuilder, FrameMetricsBuilder metricsBuilder) {
///     final PictureRecorder pictureRecorder = PictureRecorder();
///     final Canvas canvas = Canvas(pictureRecorder);
///     final Paint paint = Paint()..color = const Color.fromARGB(255, 255, 0, 0);
///     final Size windowSize = window.physicalSize;
///     canvas.drawCircle(windowSize.center(Offset.zero), 50.0, paint);
///     final Picture picture = pictureRecorder.endRecording();
///     sceneBuilder.addPicture(picture);
///   }
/// }
/// ```
abstract class RawRecorder extends Recorder {
  RawRecorder({@required String name}) : super._(name);

  /// Called from [Window.onBeginFrame].
  @mustCallSuper
  void onBeginFrame() {}

  /// Called on every frame.
  ///
  /// An implementation should exercise the [sceneBuilder] to build a frame.
  /// However, it must not call [SceneBuilder.build] or [Window.render].
  /// Instead the benchmark harness will call them and time them appropriately.
  ///
  /// The callback is given a [FrameMetricsBuilder] that can be populated
  /// with various frame-related metrics, such as paint time and layout time.
  void onDrawFrame(SceneBuilder sceneBuilder);

  @override
  Future<Profile> run() {
    final Completer<Profile> profileCompleter = Completer<Profile>();
    window.onBeginFrame = (_) {
      onBeginFrame();
    };
    window.onDrawFrame = () {
      Duration sceneBuildDuration;
      Duration windowRenderDuration;
      final Duration drawFrameDuration = timeAction(() {
        final SceneBuilder sceneBuilder = SceneBuilder();
        onDrawFrame(sceneBuilder);
        sceneBuildDuration = timeAction(() {
          final Scene scene = sceneBuilder.build();
          windowRenderDuration = timeAction(() {
            window.render(scene);
          });
        });
      });
      _frames.add(FrameMetrics(
        drawFrameDuration: drawFrameDuration,
        sceneBuildDuration: sceneBuildDuration,
        windowRenderDuration: windowRenderDuration,
      ));
      if (_shouldContinue()) {
        window.scheduleFrame();
      } else {
        final Profile profile = _generateProfile();
        profileCompleter.complete(profile);
      }
    };
    window.scheduleFrame();
    return profileCompleter.future;
  }
}

/// A recorder for benchmarking interactions with the framework by creating
/// widgets.
///
/// To implement a benchmark, extend this class and implement [createWidget].
///
/// Example:
///
/// ```
/// class BenchListView extends WidgetRecorder {
///   BenchListView() : super(name: benchmarkName);
///
///   static const String benchmarkName = 'bench_list_view';
///
///   @override
///   Widget createWidget() {
///     return Directionality(
///       textDirection: TextDirection.ltr,
///       child: _TestListViewWidget(),
///     );
///   }
/// }
///
/// class _TestListViewWidget extends StatefulWidget {
///   @override
///   State<StatefulWidget> createState() {
///     return _TestListViewWidgetState();
///   }
/// }
///
/// class _TestListViewWidgetState extends State<_TestListViewWidget> {
///   ScrollController scrollController;
///
///   @override
///   void initState() {
///     super.initState();
///     scrollController = ScrollController();
///     Timer.run(() async {
///       bool forward = true;
///       while (true) {
///         await scrollController.animateTo(
///           forward ? 300 : 0,
///           curve: Curves.linear,
///           duration: const Duration(seconds: 1),
///         );
///         forward = !forward;
///       }
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView.builder(
///       controller: scrollController,
///       itemCount: 10000,
///       itemBuilder: (BuildContext context, int index) {
///         return Text('Item #$index');
///       },
///     );
///   }
/// }
/// ```
abstract class WidgetRecorder extends Recorder {
  WidgetRecorder({@required String name}) : super._(name);

  /// Creates a widget to be benchmarked.
  ///
  /// The widget must create its own animation to drive the benchmark. The
  /// animation should continue indefinitely. The benchmark harness will stop
  /// pumping frames automatically as soon as the noise levels are sufficiently
  /// low.
  Widget createWidget();

  final Completer<Profile> _profileCompleter = Completer<Profile>();

  Stopwatch _drawFrameStopwatch;

  void _frameWillDraw() {
    _drawFrameStopwatch = Stopwatch()..start();
  }

  void _frameDidDraw() {
    _frames.add(FrameMetrics(
      drawFrameDuration: _drawFrameStopwatch.elapsed,
      sceneBuildDuration: null,
      windowRenderDuration: null,
    ));
    if (_shouldContinue()) {
      window.scheduleFrame();
    } else {
      final Profile profile = _generateProfile();
      _profileCompleter.complete(profile);
    }
  }

  @override
  Future<Profile> run() {
    final _RecordingWidgetsBinding binding =
        _RecordingWidgetsBinding.ensureInitialized();
    final Widget widget = createWidget();
    binding._beginRecording(this, widget);
    return _profileCompleter.future;
  }
}

/// Pumps frames and records frame metrics.
abstract class Recorder {
  Recorder._(this.name);

  /// The name of the benchmark being recorded.
  final String name;

  /// Frame metrics recorded during a single benchmark run.
  final List<FrameMetrics> _frames = <FrameMetrics>[];

  /// Runs the benchmark and records a profile containing frame metrics.
  Future<Profile> run();

  /// Decides whether the data collected so far is sufficient to stop, or
  /// whether the benchmark should continue collecting more data.
  ///
  /// The signals used are sample size, noise, and duration.
  bool _shouldContinue() {
    // Run through a minimum number of frames.
    if (_frames.length < _kMinSampleCount) {
      return true;
    }

    final Profile profile = _generateProfile();

    // Is it still too noisy?
    if (profile.drawFrameDurationNoise > _kNoiseThreshold) {
      // If the benchmark has run long enough, stop it, even if it's noisy under
      // the assumption that this benchmark is always noisy and there's nothing
      // we can do about it.
      if (_frames.length > _kMaxSampleCount) {
        print(
          'WARNING: Benchmark noise did not converge below ${_kNoiseThreshold * 100}%. '
          'Stopping because it reached the maximum number of samples $_kMaxSampleCount. '
          'Noise level is ${profile.drawFrameDurationNoise * 100}%.',
        );
        return false;
      }

      // Keep running.
      return true;
    }

    print(
      'SUCCESS: Benchmark converged below ${_kNoiseThreshold * 100}%. '
      'Noise level is ${profile.drawFrameDurationNoise * 100}%.',
    );
    return false;
  }

  Profile _generateProfile() {
    final List<FrameMetrics> measuredFrames =
        _frames.sublist(_frames.length - _kMeasuredSampleCount);
    final Iterable<double> noiseCheckDrawFrameTimes =
        measuredFrames.map<double>((FrameMetrics metric) =>
            metric.drawFrameDuration.inMicroseconds.toDouble());
    final double averageDrawFrameDurationMicros =
        computeMean(noiseCheckDrawFrameTimes);
    final double standardDeviation =
        computeStandardDeviationForPopulation(noiseCheckDrawFrameTimes);
    final double drawFrameDurationNoise =
        standardDeviation / averageDrawFrameDurationMicros;

    return Profile(
      name: name,
      averageDrawFrameDuration:
          Duration(microseconds: averageDrawFrameDurationMicros.toInt()),
      drawFrameDurationNoise: drawFrameDurationNoise,
      frames: measuredFrames,
    );
  }
}

/// Contains metrics for a series of rendered frames.
@immutable
class Profile {
  Profile({
    @required this.name,
    @required this.drawFrameDurationNoise,
    @required this.averageDrawFrameDuration,
    @required List<FrameMetrics> frames,
  }) : frames = List<FrameMetrics>.unmodifiable(frames);

  /// The name of the benchmark that produced this profile.
  final String name;

  /// Average amount of time [Window.onDrawFrame] took.
  final Duration averageDrawFrameDuration;

  /// The noise, as a fraction of [averageDrawFrameDuration], measure from the [frames].
  final double drawFrameDurationNoise;

  /// Frame metrics recorded during a single benchmark run.
  final List<FrameMetrics> frames;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'averageDrawFrameDuration': averageDrawFrameDuration.inMilliseconds,
      'drawFrameDurationNoise': drawFrameDurationNoise,
      'frames': frames
          .map((FrameMetrics frameMetrics) => frameMetrics.toJson())
          .toList(),
    };
  }

  @override
  String toString() {
    return _formatToStringLines(<String>[
      'benchmark: $name',
      'averageDrawFrameDuration: ${averageDrawFrameDuration.inMicroseconds}μs',
      'drawFrameDurationNoise: ${drawFrameDurationNoise * 100}%',
      'frames:',
      ...frames.expand((FrameMetrics frame) =>
          '$frame\n'.split('\n').map((String line) => '- $line\n')),
    ]);
  }
}

/// Contains metrics for a single frame.
class FrameMetrics {
  FrameMetrics({
    @required this.drawFrameDuration,
    @required this.sceneBuildDuration,
    @required this.windowRenderDuration,
  });

  /// Total amount of time taken by [Window.onDrawFrame].
  final Duration drawFrameDuration;

  /// The amount of time [SceneBuilder.build] took.
  final Duration sceneBuildDuration;

  /// The amount of time [Window.render] took.
  final Duration windowRenderDuration;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'drawFrameDuration': drawFrameDuration.inMicroseconds,
      if (sceneBuildDuration != null)
        'sceneBuildDuration': sceneBuildDuration.inMicroseconds,
      if (windowRenderDuration != null)
        'windowRenderDuration': windowRenderDuration.inMicroseconds,
    };
  }

  @override
  String toString() {
    return _formatToStringLines(<String>[
      'drawFrameDuration: ${drawFrameDuration.inMicroseconds}μs',
      if (sceneBuildDuration != null)
        'sceneBuildDuration: ${sceneBuildDuration.inMicroseconds}μs',
      if (windowRenderDuration != null)
        'windowRenderDuration: ${windowRenderDuration.inMicroseconds}μs',
    ]);
  }
}

String _formatToStringLines(List<String> lines) {
  return lines
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .join('\n');
}

/// Computes the arithmetic mean (or average) of given [values].
double computeMean(Iterable<double> values) {
  final double sum = values.reduce((double a, double b) => a + b);
  return sum / values.length;
}

/// Computes population standard deviation.
///
/// Unlike sample standard deviation, which divides by N - 1, this divides by N.
///
/// See also:
///
/// * https://en.wikipedia.org/wiki/Standard_deviation
double computeStandardDeviationForPopulation(Iterable<double> population) {
  final double mean = computeMean(population);
  final double sumOfSquaredDeltas = population.fold<double>(
    0.0,
    (double previous, double value) => previous += math.pow(value - mean, 2),
  );
  return math.sqrt(sumOfSquaredDeltas / population.length);
}

/// A variant of [WidgetsBinding] that collaborates with a [Recorder] to decide
/// when to stop pumping frames.
///
/// A normal [WidgetsBinding] typically always pumps frames whenever a widget
/// instructs it to do so by calling [scheduleFrame] (transitively via
/// `setState`). This binding will stop pumping new frames as soon as benchmark
/// parameters are satisfactory (e.g. when the metric noise levels become low
/// enough).
class _RecordingWidgetsBinding extends BindingBase
    with
        GestureBinding,
        ServicesBinding,
        SchedulerBinding,
        PaintingBinding,
        SemanticsBinding,
        RendererBinding,
        WidgetsBinding {
  /// Makes an instance of [_RecordingWidgetsBinding] the current binding.
  static _RecordingWidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null) {
      _RecordingWidgetsBinding();
    }
    return WidgetsBinding.instance as _RecordingWidgetsBinding;
  }

  WidgetRecorder _recorder;

  void _beginRecording(WidgetRecorder recorder, Widget widget) {
    _recorder = recorder;
    runApp(widget);
  }

  /// To avoid calling [Recorder._shouldContinue] every time [scheduleFrame] is
  /// called, we cache this value at the beginning of the frame.
  bool _benchmarkStopped = false;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    _benchmarkStopped = !_recorder._shouldContinue();
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void scheduleFrame() {
    if (!_benchmarkStopped) {
      super.scheduleFrame();
    }
  }

  @override
  void handleDrawFrame() {
    _recorder._frameWillDraw();
    super.handleDrawFrame();
    _recorder._frameDidDraw();
  }
}
