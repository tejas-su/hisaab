/// The only ways prompt text leaves the app, each started by the user's tap (SPEC BR-15, NFR-2).
abstract interface class AiHandoff {
  /// Puts [text] on the clipboard; completes once it is there.
  Future<void> copy(String text);

  /// Opens [link] in the ChatGPT app or the browser.
  ///
  /// Completes with false when nothing could open it; never throws.
  Future<bool> open(Uri link);

  /// Opens the Android share sheet with [text]; completes when the sheet closes.
  Future<void> share(String text);
}
