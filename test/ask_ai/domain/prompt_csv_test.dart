import 'package:hisaab/ask_ai/domain/prompt_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptCsv.field (RFC 4180)', () {
    test('leaves plain text alone', () => expect(PromptCsv.field('Chai & samosa'), 'Chai & samosa'));
    test('leaves an empty field empty', () => expect(PromptCsv.field(''), ''));
    test('quotes commas', () => expect(PromptCsv.field('Rice, dal'), '"Rice, dal"'));
    test('doubles quotes', () => expect(PromptCsv.field('5" pizza'), '"5"" pizza"'));
    test('quotes line breaks', () => expect(PromptCsv.field('a\nb'), '"a\nb"'));
    test('quotes carriage returns', () => expect(PromptCsv.field('a\rb'), '"a\rb"'));
  });
}
