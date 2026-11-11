import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/domain/entities/entry_draft.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entry_validator.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);

EntryDraft _draft({Money? amount, CalendarDate date = _today, String? note}) => EntryDraft(
      amount: amount ?? Money.fromMajor(420),
      kind: EntryKind.spent,
      categoryId: 1,
      date: date,
      note: note,
    );

Failure _failureOf(Either<Failure, EntryDraft> result) =>
    result.match((Failure failure) => failure, (EntryDraft _) => fail('expected a failure'));

void main() {
  group('EntryValidator.validate (BR-10)', () {
    test('accepts a typical entry', () {
      expect(EntryValidator.validate(_draft(), today: _today), Either<Failure, EntryDraft>.right(_draft()));
    });

    test('accepts ₹1 and the 9-digit maximum (E11)', () {
      expect(EntryValidator.validate(_draft(amount: Money.fromMajor(1)), today: _today).isRight(), isTrue);
      expect(EntryValidator.validate(_draft(amount: Money.fromMajor(999999999)), today: _today).isRight(), isTrue);
    });

    final List<(String, Money)> badAmounts = <(String, Money)>[
      ('₹0', Money.zero),
      ('a negative amount', Money.fromMajor(-5)),
      ('less than a rupee', const Money(99)),
      ('10 digits', Money.fromMajor(1000000000)),
    ];
    for (final (String name, Money amount) in badAmounts) {
      test('rejects $name', () {
        expect(_failureOf(EntryValidator.validate(_draft(amount: amount), today: _today)), isA<InvalidAmountFailure>());
      });
    }

    test('accepts yesterday but rejects tomorrow', () {
      expect(EntryValidator.validate(_draft(date: _today.addDays(-1)), today: _today).isRight(), isTrue);
      expect(_failureOf(EntryValidator.validate(_draft(date: _today.addDays(1)), today: _today)), isA<FutureDateFailure>());
    });

    test('trims the note', () {
      expect(
        EntryValidator.validate(_draft(note: '  Chai  '), today: _today),
        Either<Failure, EntryDraft>.right(_draft(note: 'Chai')),
      );
    });

    test('a blank note becomes no note', () {
      expect(EntryValidator.validate(_draft(note: '   '), today: _today), Either<Failure, EntryDraft>.right(_draft()));
    });

    test('allows 80 characters after trimming, rejects 81', () {
      expect(EntryValidator.validate(_draft(note: ' ${'a' * 80} '), today: _today).isRight(), isTrue);
      expect(_failureOf(EntryValidator.validate(_draft(note: 'a' * 81), today: _today)), isA<NoteTooLongFailure>());
    });

    test('counts unicode notes by characters', () {
      expect(EntryValidator.validate(_draft(note: 'चाय और समोसा'), today: _today).isRight(), isTrue);
    });
  });
}
