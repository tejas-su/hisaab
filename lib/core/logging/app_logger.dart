import 'dart:developer' as developer;

/// The app's only logger; writes to the device log and never leaves the phone (SPEC NFR-3).
///
/// Never pass notes or other personal text in [log] data.
abstract final class AppLogger {
  static const String _name = 'hisaab';

  /// Logs a diagnostic event under [tag] with optional structured [data].
  static void log({required String tag, Map<String, Object?> data = const <String, Object?>{}}) {
    developer.log('$tag $data', name: _name);
  }

  /// Logs an unexpected [error] with its [stackTrace].
  static void recordError(Object error, StackTrace stackTrace, {String tag = 'error'}) {
    developer.log(tag, name: _name, error: error, stackTrace: stackTrace, level: 1000);
  }
}
