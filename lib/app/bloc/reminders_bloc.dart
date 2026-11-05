import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/notifications/bill_reminder.dart';
import '../../core/notifications/bill_reminders.dart';
import '../../core/usecases/use_case.dart';
import '../../ledger/ledger.dart';
import '../../settings/settings.dart';
import 'reminders_event.dart';
import 'reminders_state.dart';

/// Keeps the bill reminders armed and turns a tap on one into the bill's amount sheet (spec §6,
/// D126). Driven by [RemindersStarted], [RemindersArmRequested] (resume, and every write through
/// the ledger and rule change streams) and the taps of [BillReminders].
class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  RemindersBloc({
    required this._preferences,
    required this._arm,
    required this._reminders,
    required this._getCycleSummary,
    required LedgerRepository ledger,
    required RecurringRepository recurring,
  }) : super(const RemindersIdle()) {
    on<RemindersStarted>(_onStarted);
    // why: an arm writes to the system, which a cancel can't undo; one at a time, in order, so
    // the newest bills are always armed last.
    on<RemindersArmRequested>((RemindersArmRequested event, Emitter<RemindersState> emit) => _armNow(), transformer: sequential());
    on<RemindersTapped>((RemindersTapped event, Emitter<RemindersState> emit) => _open(emit, event.tap));
    _taps = _reminders.taps.listen((BillReminderTap tap) => add(RemindersTapped(tap)));
    _changes = ledger.changes.listen((void _) => add(const RemindersArmRequested()));
    _ruleChanges = recurring.changes.listen((void _) => add(const RemindersArmRequested()));
  }

  final AppPreferencesRepository _preferences;
  final ArmBillReminders _arm;
  final BillReminders _reminders;
  final GetCycleSummary _getCycleSummary;
  late final StreamSubscription<BillReminderTap> _taps;
  late final StreamSubscription<void> _changes;
  late final StreamSubscription<void> _ruleChanges;

  Future<void> _onStarted(RemindersStarted event, Emitter<RemindersState> emit) async {
    final Option<BillReminderTap> launched = await _reminders.launchTap();
    if (launched case Some(:final BillReminderTap value)) {
      await _open(emit, value);
    }
    await _armNow();
  }

  /// Arms the reminders if the user said *Remind me*, and removes them otherwise.
  Future<void> _armNow() async {
    final Either<Failure, Unit> armed = await _preferences
        .billRemindersChoice()
        .flatMap((Option<bool> choice) => _arm(choice.getOrElse(() => false)))
        .run();
    armed.mapLeft(_logFailure('reminders.arm_failed'));
  }

  Future<void> _open(Emitter<RemindersState> emit, BillReminderTap tap) async {
    final Option<Occurrence> bill = (await _getCycleSummary(const NoParams()).run()).match(
      (Failure failure) {
        _logFailure('reminders.open_failed')(failure);
        return const Option<Occurrence>.none();
      },
      (CycleSummary summary) => Option<Occurrence>.fromNullable(
        summary.waitingBills.where((Occurrence o) => o.rule.id == tap.ruleId && o.date == tap.date).firstOrNull,
      ),
    );
    emit(RemindersBillOpened(bill));
    // why: back to idle, so a second tap on the same reminder opens it again.
    emit(const RemindersIdle());
  }

  static void Function(Failure) _logFailure(String tag) =>
      (Failure failure) => AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _taps.cancel();
    await _changes.cancel();
    await _ruleChanges.cancel();
    return super.close();
  }
}
