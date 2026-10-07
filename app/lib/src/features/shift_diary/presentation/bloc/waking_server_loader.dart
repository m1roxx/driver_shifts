import 'dart:async';

import 'package:driver_shifts/src/core/domain/result.dart';

class WakingServerTimings {
  const WakingServerTimings({
    this.slowAfter = const Duration(seconds: 3),
    this.retryEvery = const Duration(seconds: 5),
    this.retryFor = const Duration(seconds: 90),
  });

  final Duration slowAfter;
  final Duration retryEvery;
  final Duration retryFor;
}

class WakingServerLoader {
  WakingServerLoader([this._timings = const WakingServerTimings()]);

  final WakingServerTimings _timings;
  final Set<Timer> _timers = {};

  Future<Result<T>?> load<T>(
    Future<Result<T>> Function() request, {
    required bool Function() cancelled,
    required void Function() onSlow,
  }) async {
    final slow = _after(_timings.slowAfter, () {
      if (!cancelled()) onSlow();
    });
    var retrying = true;
    final deadline = _after(_timings.retryFor, () => retrying = false);
    try {
      while (true) {
        final result = await request();
        if (cancelled()) return null;
        switch (result) {
          case SuccessResult():
            return result;
          case ErrorResult(:final failure)
              when !failure.isTransient || !retrying:
            return result;
          case ErrorResult():
            await _pause(_timings.retryEvery);
            if (cancelled()) return null;
        }
      }
    } finally {
      _cancel(slow);
      _cancel(deadline);
    }
  }

  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  Timer _after(Duration delay, void Function() callback) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      callback();
    });
    _timers.add(timer);
    return timer;
  }

  void _cancel(Timer timer) {
    timer.cancel();
    _timers.remove(timer);
  }

  Future<void> _pause(Duration delay) {
    final done = Completer<void>();
    _after(delay, done.complete);
    return done.future;
  }
}
