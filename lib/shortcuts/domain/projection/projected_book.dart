import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_switch.dart';
import '../../../ledger/ledger.dart';

/// An in-memory copy of the ledger, rules, skips and settings, on which the real recurring engine
/// and `GetCycleSummary` run for days still to come (widget spec §5).
///
/// The engine's posts land here, never in the database. Nothing else writes: the widget's rows
/// assume no new typed entries (FR-WG-5), so every write the app makes elsewhere is unsupported.
final class ProjectedBook {
  ProjectedBook({
    required List<Entry> entries,
    required List<RecurringRule> rules,
    required List<BillSkip> skips,
    required this.settings,
    required this.firstLogged,
  })  : _entries = <Entry>[...entries],
        _rules = <RecurringRule>[...rules],
        _skips = <BillSkip>[...skips];

  final List<Entry> _entries;
  final List<RecurringRule> _rules;
  final List<BillSkip> _skips;

  /// The settings as stored when the copy was made.
  final BudgetSettings settings;

  /// The ledger's first logged day when the copy was made.
  final Option<CalendarDate> firstLogged;

  /// The day the engine is running on; its posts are saved on it, as the database stamps a post
  /// with the time it was made.
  CalendarDate runningOn = CalendarDate(1970, 1, 1);

  /// The copy seen as a [LedgerRepository].
  late final LedgerRepository ledger = _ProjectedLedger(this);

  /// The copy seen as a [RecurringRepository].
  late final RecurringRepository recurring = _ProjectedRecurring(this);

  /// The copy seen as a [BudgetSettingsRepository].
  late final BudgetSettingsRepository budget = _ProjectedSettings(this);

  /// [day]'s *Spent* entries that no rule posted, oldest first, as Home's today's bar takes them.
  List<Entry> typedSpendsOn(CalendarDate day) => _newestFirst(_entries.where((Entry e) => e.date == day))
      .reversed
      .where((Entry e) => e.kind == EntryKind.spent && e.recurringId == null && !e.isNotLogged)
      .toList();

  Option<CalendarDate> _earliestSaved() => Option<CalendarDate>.fromNullable(
        _entries.map((Entry e) => CalendarDate.fromDateTime(e.createdAt)).fold<CalendarDate?>(
              null,
              (CalendarDate? first, CalendarDate day) => first == null || day.isBefore(first) ? day : first,
            ),
      );

  List<Entry> _between(CalendarDate from, CalendarDate to) =>
      _newestFirst(_entries.where((Entry e) => !e.date.isBefore(from) && !e.date.isAfter(to)));

  // why: the same order as the database's read (date, then id, newest first), so every list built
  // from it comes out as Home's does.
  static List<Entry> _newestFirst(Iterable<Entry> entries) => entries.toList()
    ..sort((Entry a, Entry b) => a.date == b.date ? b.id.compareTo(a.id) : b.date.compareTo(a.date));

  // why: as the database's post: an occurrence already posted or skipped for that rule and date is
  // left out, and each rule's next due date moves on.
  int _post(RecurringPosting posting) {
    int nextId = _entries.fold(0, (int top, Entry e) => e.id > top ? e.id : top);
    int inserted = 0;
    for (final Occurrence occurrence in posting.occurrences) {
      if (_answered(occurrence)) {
        continue;
      }
      final RecurringRule rule = occurrence.rule;
      _entries.add(
        Entry(
          id: ++nextId,
          amount: rule.amount,
          kind: rule.kind,
          categoryId: rule.categoryId,
          date: occurrence.date,
          createdAt: DateTime(runningOn.year, runningOn.month, runningOn.day),
          note: rule.kind == EntryKind.saved ? rule.label : null,
          recurringId: rule.id,
        ),
      );
      inserted++;
    }
    for (int i = 0; i < _rules.length; i++) {
      if (posting.nextDueByRuleId[_rules[i].id] case final CalendarDate next) {
        _rules[i] = _rules[i].copyWith(nextDue: next);
      }
    }
    return inserted;
  }

  bool _answered(Occurrence occurrence) {
    bool same(int? ruleId, CalendarDate date) => ruleId == occurrence.rule.id && date == occurrence.date;
    return _entries.any((Entry e) => same(e.recurringId, e.date)) || _skips.any((BillSkip s) => same(s.ruleId, s.date));
  }
}

/// [ProjectedBook]'s entries: reads only, apart from the engine's posts.
final class _ProjectedLedger implements LedgerRepository {
  const _ProjectedLedger(this._book);

  final ProjectedBook _book;

  @override
  TaskEither<Failure, List<Entry>> entriesBetween(CalendarDate from, CalendarDate to) =>
      TaskEither<Failure, List<Entry>>.right(_book._between(from, to));

  // why: on an empty ledger the engine's first post is the first thing saved, as in the database.
  @override
  TaskEither<Failure, Option<CalendarDate>> firstLoggedOn() => TaskEither<Failure, Option<CalendarDate>>.right(
        _book.firstLogged.alt(_book._earliestSaved),
      );

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  TaskEither<Failure, Entry> add(EntryDraft draft) => throw _readOnly;

  @override
  TaskEither<Failure, Entry> addForRule(EntryDraft draft, {required int recurringId}) => throw _readOnly;

  @override
  TaskEither<Failure, Entry> addForSaving(EntryDraft draft, {required int savingId}) => throw _readOnly;

  @override
  TaskEither<Failure, Entry> replace(int id, EntryDraft draft) => throw _readOnly;

  @override
  TaskEither<Failure, Entry> delete(int id) => throw _readOnly;

  @override
  TaskEither<Failure, Entry> restore(Entry entry) => throw _readOnly;

  @override
  TaskEither<Failure, Option<SavedTotal>> savedTotal() => throw _readOnly;

  @override
  TaskEither<Failure, SavingTotals> savingTotals() => throw _readOnly;
}

/// [ProjectedBook]'s rules and skips; [post] is the only write.
final class _ProjectedRecurring implements RecurringRepository {
  const _ProjectedRecurring(this._book);

  final ProjectedBook _book;

  @override
  TaskEither<Failure, List<RecurringRule>> activeRules() =>
      TaskEither<Failure, List<RecurringRule>>.right(List<RecurringRule>.unmodifiable(_book._rules));

  @override
  TaskEither<Failure, int> post(RecurringPosting posting) => TaskEither<Failure, int>(() async => Either<Failure, int>.right(_book._post(posting)));

  @override
  TaskEither<Failure, List<BillSkip>> skipsBetween(CalendarDate from, CalendarDate to) => TaskEither<Failure, List<BillSkip>>.right(
        _book._skips.where((BillSkip s) => !s.date.isBefore(from) && !s.date.isAfter(to)).toList(),
      );

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  TaskEither<Failure, Unit> startFresh(LedgerSetup setup) => throw _readOnly;

  @override
  TaskEither<Failure, RecurringRule> add(RecurringDraft draft) => throw _readOnly;

  @override
  TaskEither<Failure, RecurringRule> update(RecurringRule rule) => throw _readOnly;

  @override
  TaskEither<Failure, Unit> setActive(int id, {required bool active}) => throw _readOnly;

  @override
  TaskEither<Failure, Unit> skip(BillSkip skip) => throw _readOnly;

  @override
  TaskEither<Failure, Unit> unskip(BillSkip skip) => throw _readOnly;
}

/// [ProjectedBook]'s settings, as stored.
final class _ProjectedSettings implements BudgetSettingsRepository {
  const _ProjectedSettings(this._book);

  final ProjectedBook _book;

  @override
  TaskEither<Failure, BudgetSettings> read() => TaskEither<Failure, BudgetSettings>.right(_book.settings);

  @override
  TaskEither<Failure, Unit> addPaySwitch(PaySwitch change) => throw _readOnly;

  // why: the install line is a Home line; no projected day reads it, and it can't be written here.
  @override
  TaskEither<Failure, bool> installLineSeen() => TaskEither<Failure, bool>.right(true);

  @override
  TaskEither<Failure, Unit> markInstallLineSeen() => throw _readOnly;
}

// why: only the engine and the summary run on the copy; any other write is a programming error,
// and a projected row must never pretend a user's change happened.
final UnsupportedError _readOnly = UnsupportedError('A projected ledger only takes the engine\'s posts.');
