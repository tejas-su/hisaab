import 'package:fpdart/fpdart.dart';

/// The ChatGPT links Ask AI opens (SPEC BR-15).
abstract final class ChatGptLink {
  /// The longest URL-encoded prompt the `?q=` link carries.
  static const int maxEncodedLength = 2000;

  /// The bare site, opened when the prompt is too long to prefill.
  static final Uri home = Uri.parse('https://chatgpt.com/');

  /// The link that prefills [text], or [None] when its encoding is over [maxEncodedLength].
  static Option<Uri> prefilled(String text) {
    final String encoded = Uri.encodeComponent(text);
    return encoded.length <= maxEncodedLength
        ? Option<Uri>.of(Uri.parse('https://chatgpt.com/?q=$encoded'))
        : const Option<Uri>.none();
  }
}
