import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../time/calendar_date.dart';

/// One due-day reminder for a changing or card bill's occurrence (spec §6, D126).
final class BillReminder extends Equatable {
  const BillReminder({required this.ruleId, required this.date, required this.billName, required this.isCard, required this.at});

  final int ruleId;

  /// The occurrence's due date.
  final CalendarDate date;

  /// The bill's name as the user wrote it; never an amount or a note.
  final String billName;

  /// True for a card bill, whose reminder says it is due rather than that it went out.
  final bool isCard;

  /// When it shows, in local time.
  final DateTime at;

  /// The notification id: the same occurrence always gets the same id, so arming twice never
  /// shows two.
  int get id => idFor(ruleId, date);

  /// What a tap on it opens.
  BillReminderTap get tap => BillReminderTap(ruleId: ruleId, date: date);

  /// The id of [ruleId]'s reminder for [date].
  // why: Android ids are 32-bit; days since 2020 stay under 100,000 for 270 years, so rule ids
  // up to 21,474 fit without two occurrences sharing an id.
  static int idFor(int ruleId, CalendarDate date) => ruleId * _daysPerRule + _epoch.daysUntil(date);

  static const int _daysPerRule = 100000;
  static const CalendarDate _epoch = CalendarDate(2020, 1, 1);

  @override
  List<Object?> get props => <Object?>[ruleId, date, billName, isCard, at];
}

/// A tap on a [BillReminder]: which bill and which due date to ask about. Carried as the link
/// `hisaab://bill/{ruleId}/{date}` (spec §6).
final class BillReminderTap extends Equatable {
  const BillReminderTap({required this.ruleId, required this.date});

  final int ruleId;
  final CalendarDate date;

  /// The link the notification carries, e.g. `hisaab://bill/3/2026-11-18`.
  String get link => 'hisaab://bill/$ruleId/$date';

  /// Reads [link]; [None] for anything that isn't a bill link.
  static Option<BillReminderTap> parse(String? link) {
    final Uri? uri = link == null ? null : Uri.tryParse(link);
    if (uri == null || uri.scheme != 'hisaab' || uri.host != 'bill' || uri.pathSegments.length != 2) {
      return const Option<BillReminderTap>.none();
    }
    final int? ruleId = int.tryParse(uri.pathSegments.first);
    return Option<int>.fromNullable(ruleId).flatMap(
      (int id) => CalendarDate.parse(uri.pathSegments.last).toOption().map((CalendarDate date) => BillReminderTap(ruleId: id, date: date)),
    );
  }

  @override
  List<Object?> get props => <Object?>[ruleId, date];
}
