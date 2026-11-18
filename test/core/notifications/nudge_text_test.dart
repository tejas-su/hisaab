import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/notifications/nudge_notice.dart';
import 'package:hisaab/core/notifications/nudge_text.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';

void main() {
  final AppLocalizations strings = lookupAppLocalizations(const Locale('en', 'IN'));
  NudgeNotice general(DateTime at) => NudgeNotice(id: 1, at: at, categoryName: const Option<String>.none());
  NudgeNotice named(DateTime at, String name) => NudgeNotice(id: 1, at: at, categoryName: Option<String>.of(name));

  group('NudgeText.variantFor', () {
    test('cycles 0, 1, 2, 0 over consecutive days', () {
      final List<int> variants =
          List<int>.generate(4, (int i) => NudgeText.variantFor(DateTime(2026, 11, 18 + i, 20)));

      expect(variants.sublist(0, 3).toSet(), <int>{0, 1, 2});
      expect(variants[3], variants[0]);
      expect(variants[1], (variants[0] + 1) % 3);
      expect(variants[2], (variants[1] + 1) % 3);
    });

    test('is the same all day long', () {
      expect(NudgeText.variantFor(DateTime(2026, 11, 18, 0, 1)), NudgeText.variantFor(DateTime(2026, 11, 18, 23, 59)));
    });

    test('keeps cycling across a month and a year end', () {
      expect(NudgeText.variantFor(DateTime(2027, 1, 1)), (NudgeText.variantFor(DateTime(2026, 12, 31)) + 1) % 3);
      expect(NudgeText.variantFor(DateTime(2024, 3, 1)), (NudgeText.variantFor(DateTime(2024, 2, 29)) + 1) % 3);
    });
  });

  group('NudgeText.of', () {
    final List<DateTime> threeDays = <DateTime>[DateTime(2026, 11, 18, 20), DateTime(2026, 11, 19, 20), DateTime(2026, 11, 20, 20)];

    test('the three phrasings of a category nudge differ', () {
      final List<({String title, String body})> texts = threeDays.map((DateTime d) => NudgeText.of(strings, named(d, 'Chai'))).toList();

      expect(texts.map((({String title, String body}) t) => t.title).toSet(), hasLength(3));
      expect(texts.map((({String title, String body}) t) => t.body).toSet(), hasLength(3));
    });

    test('the three phrasings of a general nudge differ and never name a category', () {
      final List<({String title, String body})> texts = threeDays.map((DateTime d) => NudgeText.of(strings, general(d))).toList();

      expect(texts.map((({String title, String body}) t) => t.title).toSet(), hasLength(3));
      expect(texts.map((({String title, String body}) t) => t.body).toSet(), hasLength(3));
    });

    test('a category nudge differs from the general one on the same day', () {
      final DateTime day = threeDays.first;

      expect(NudgeText.of(strings, named(day, 'Chai')).title, isNot(NudgeText.of(strings, general(day)).title));
      expect(NudgeText.of(strings, named(day, 'Chai')).title, contains('Chai'));
    });

    test('the same date gives the same text', () {
      expect(NudgeText.of(strings, named(DateTime(2026, 11, 18, 8), 'Chai')), NudgeText.of(strings, named(DateTime(2026, 11, 18, 21), 'Chai')));
    });

    test('inserts a category with punctuation or non-Latin text unescaped', () {
      for (final String name in <String>["Kid's <school> & co", 'चाय', '{category}']) {
        for (final DateTime day in threeDays) {
          expect(NudgeText.of(strings, named(day, name)).title, contains(name));
        }
      }
    });

    test('never carries a digit or the rupee sign', () {
      final RegExp amountLike = RegExp(r'[0-9₹]');
      for (final DateTime day in threeDays) {
        for (final NudgeNotice notice in <NudgeNotice>[general(day), named(day, 'Chai')]) {
          final ({String title, String body}) text = NudgeText.of(strings, notice);
          expect(amountLike.hasMatch(text.title), isFalse, reason: text.title);
          expect(amountLike.hasMatch(text.body), isFalse, reason: text.body);
        }
      }
    });
  });
}
