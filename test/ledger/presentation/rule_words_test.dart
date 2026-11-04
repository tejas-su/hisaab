import 'package:expense_tracker/core/design/app_icons.dart';
import 'package:expense_tracker/l10n/gen/app_localizations.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/ledger/presentation/rule_glyph.dart';
import 'package:expense_tracker/ledger/presentation/rule_words.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/ledger/worked_example.dart';

final AppLocalizations _strings = lookupAppLocalizations(const Locale('en'));

void main() {
  group('RuleWords (D120)', () {
    test('bill and saving words differ only where they should', () {
      expect(_strings.ruleDayQuestion(EntryKind.spent, 'Rent'), 'Which day does Rent go out?');
      expect(_strings.ruleDayQuestion(EntryKind.saved, 'RD'), 'Which day does RD go in?');
      expect(_strings.ruleAmountQuestion(EntryKind.saved, 'RD'), 'How much goes into RD?');
      expect(_strings.ruleAmountQuestion(EntryKind.spent, 'Rent'), 'How much is Rent?');
      expect(_strings.ruleDeleted(WorkedExample.rd), 'Deleted RD');
      expect(_strings.ruleDeleted(WorkedExample.rent), 'Deleted Rent');
    });

    test('every list and sheet word has a saving form', () {
      expect(
        <String>[
          _strings.ruleListTitle(EntryKind.saved),
          _strings.ruleListHint(EntryKind.saved),
          _strings.ruleAdd(EntryKind.saved),
          _strings.ruleNone(EntryKind.saved),
          _strings.ruleNameQuestion(EntryKind.saved),
          _strings.ruleNameHint(EntryKind.saved),
          _strings.ruleEyebrow(EntryKind.saved),
          _strings.ruleDelete(EntryKind.saved),
          _strings.ruleNext(EntryKind.saved, '10 Nov'),
          _strings.ruleStampDue(EntryKind.saved, 1),
          _strings.ruleStampCounted(EntryKind.saved, '10 Oct'),
          _strings.ruleStampCountedToday(EntryKind.saved),
        ],
        <String>[
          'Savings',
          _strings.savingsHint,
          'Add a saving',
          _strings.noSavings,
          'What do you save in?',
          _strings.savingNameHint,
          'Saving',
          'Delete saving',
          'Next goes in on 10 Nov',
          'Goes in tomorrow',
          'Put in 10 Oct',
          'Put in today',
        ],
      );
    });

    test('a bill keeps every bill word', () {
      expect(
        <String>[
          _strings.ruleListTitle(EntryKind.spent),
          _strings.ruleAdd(EntryKind.spent),
          _strings.ruleEyebrow(EntryKind.spent),
          _strings.ruleDelete(EntryKind.spent),
          _strings.ruleNext(EntryKind.spent, '10 Nov'),
          _strings.ruleStampCounted(EntryKind.spent, '10 Oct'),
        ],
        <String>['Fixed bills', 'Add a bill', 'Fixed bill', 'Delete bill', 'Next goes out on 10 Nov', 'Counted 10 Oct'],
      );
    });

    test('the nudge says goes out for a bill and goes in for a saving', () {
      expect(_strings.ruleGoesOut(WorkedExample.electricity, '₹1,200', 3, 'Thu'), 'Electricity ₹1,200 goes out in 3 days');
      expect(_strings.ruleGoesOut(WorkedExample.rd, '₹5,000', 2, 'Thu'), 'RD ₹5,000 goes in on Thu');
      expect(_strings.ruleGoesOut(WorkedExample.rd, '₹5,000', 1, 'Thu'), 'RD ₹5,000 goes in tomorrow');
      expect(_strings.ruleOpensHint(EntryKind.saved), 'Opens the saving.');
      expect(_strings.ruleOpensHint(EntryKind.spent), 'Opens the bill.');
    });
  });

  group('RuleGlyph (D120)', () {
    test('a saving shows the piggy bank and a bill its own icon', () {
      expect(WorkedExample.rd.glyph, AppIcons.saving);
      expect(WorkedExample.rent.glyph, WorkedExample.rent.shownIcon.glyph);
    });
  });
}
