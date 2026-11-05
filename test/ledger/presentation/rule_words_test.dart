import 'package:expense_tracker/core/design/app_icons.dart';
import 'package:expense_tracker/core/money/money.dart';
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
      expect(_strings.ruleDayQuestion(EntryKind.spent, 'Rent'), 'Which day of the month for Rent?');
      expect(_strings.ruleDayQuestion(EntryKind.saved, 'RD'), 'Which day of the month for RD?');
      expect(_strings.ruleAmountQuestion(EntryKind.saved, 'RD', AmountMode.fixed), 'How much do you put in RD each month?');
      expect(_strings.ruleAmountQuestion(EntryKind.spent, 'Rent', AmountMode.fixed), 'How much for Rent each month?');
      expect(_strings.ruleDeleted(WorkedExample.rd), 'RD deleted');
      expect(_strings.ruleDeleted(WorkedExample.rent), 'Rent deleted');
    });

    group('entryRemoved', () {
      Entry entry({required EntryKind kind, int? recurringId, String? note}) => Entry(
            id: 50,
            amount: Money.fromMajor(500),
            kind: kind,
            categoryId: 1,
            date: WorkedExample.today,
            createdAt: WorkedExample.now,
            recurringId: recurringId,
            note: note,
          );

      test('a saving its rule put in reads as a skipped month (case study 17)', () {
        expect(_strings.entryRemoved(entry(kind: EntryKind.saved, recurringId: 4, note: 'RD'), '₹500'), 'RD skipped this month');
      });

      test('a rule\'s saving with no note is named Saving', () {
        expect(_strings.entryRemoved(entry(kind: EntryKind.saved, recurringId: 4), '₹500'), 'Saving skipped this month');
      });

      test('an extra put in by hand is deleted like any entry', () {
        expect(_strings.entryRemoved(entry(kind: EntryKind.saved), '₹500'), '₹500 deleted');
      });

      test('a bill a rule posted is deleted like any entry', () {
        expect(_strings.entryRemoved(entry(kind: EntryKind.spent, recurringId: 1), '₹500'), '₹500 deleted');
      });
    });

    test('a changing or card bill asks about how much (D123)', () {
      expect(_strings.ruleAmountQuestion(EntryKind.spent, 'Electricity', AmountMode.varies), 'About how much for Electricity each month?');
      expect(_strings.ruleAmountQuestion(EntryKind.spent, 'HDFC card', AmountMode.card), 'About how much for HDFC card each month?');
      expect(_strings.ruleAmountQuestion(EntryKind.saved, 'RD', AmountMode.fixed), 'How much do you put in RD each month?');
    });

    test('the mode words (D123)', () {
      expect(AmountMode.values.map(_strings.amountModeName), <String>['Same every month', 'Changes every month', 'Credit card']);
    });

    test('the waiting line, today or earlier, changing or card (D123)', () {
      final RecurringRule varies = WorkedExample.electricity.copyWith(amountMode: AmountMode.varies);
      final RecurringRule card = WorkedExample.electricity.copyWith(label: 'HDFC card', amountMode: AmountMode.card);
      expect(_strings.ruleWaiting(varies, '24 Oct', isToday: true), 'Electricity went out today. How much?');
      expect(_strings.ruleWaiting(varies, '24 Oct', isToday: false), 'Electricity went out on 24 Oct. How much?');
      expect(_strings.ruleWaiting(card, '24 Oct', isToday: true), 'HDFC card bill is due today. How much did you pay?');
      expect(_strings.ruleWaiting(card, '24 Oct', isToday: false), 'HDFC card bill was due on 24 Oct. How much did you pay?');
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
          'Next due on 10 Nov',
          'Due tomorrow',
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
        <String>['Bills', 'Add a bill', 'Bill', 'Delete bill', 'Next due on 10 Nov', 'Went out 10 Oct'],
      );
    });

    test('the nudge says goes out for a bill and goes in for a saving', () {
      expect(_strings.ruleGoesOut(WorkedExample.electricity, '₹1,200', 3, 'Thu'), 'Electricity, ₹1,200, due in 3 days');
      expect(_strings.ruleGoesOut(WorkedExample.rd, '₹5,000', 2, 'Thu'), 'RD, ₹5,000, due on Thu');
      expect(_strings.ruleGoesOut(WorkedExample.rd, '₹5,000', 1, 'Thu'), 'RD, ₹5,000, due tomorrow');
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
