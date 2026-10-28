import 'package:expense_tracker/ask_ai/domain/chat_gpt_link.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('ChatGptLink.prefilled (BR-15)', () {
    test('carries text whose encoding is exactly 2,000 chars', () {
      final String text = 'a' * 2000;
      expect(ChatGptLink.prefilled(text), Option<Uri>.of(Uri.parse('https://chatgpt.com/?q=$text')));
    });

    test('is None at 2,001 encoded chars', () {
      expect(ChatGptLink.prefilled('a' * 2001), const Option<Uri>.none());
    });

    test('measures the encoded length, not the raw one', () {
      // '₹' encodes to %E2%82%B9 (9 chars): 223 × 9 = 2,007 > 2,000.
      expect(ChatGptLink.prefilled('₹' * 223), const Option<Uri>.none());
    });

    test('encodes spaces as %20, not +', () {
      expect(ChatGptLink.prefilled('a b'), Option<Uri>.of(Uri.parse('https://chatgpt.com/?q=a%20b')));
    });
  });

  test('home is the bare ChatGPT site', () {
    expect(ChatGptLink.home, Uri.parse('https://chatgpt.com/'));
  });
}
