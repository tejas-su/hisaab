import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// The app's only logger; writes to the debug log in debug and profile builds and does nothing in release (SPEC NFR-3).
///
/// Never pass notes or other personal text in [log] data.
abstract final class AppLogger {
  static const String _name = 'hisaab';

  /// Logs a diagnostic event under [tag] with optional structured [data].
  static void log({required String tag, Map<String, Object?> data = const <String, Object?>{}}) {
    if (kReleaseMode) return;
    developer.log('$tag $data', name: _name);
  }

  /// Logs an unexpected [error] with its [stackTrace].
  static void recordError(Object error, StackTrace stackTrace, {String tag = 'error'}) {
    if (kReleaseMode) return;
    developer.log(tag, name: _name, error: error, stackTrace: stackTrace, level: 1000);
  }
}
