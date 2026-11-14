import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../habits/habits.dart';

/// The missed-log line Home shows, if any (SPEC FR-HO-3).
final class HomeLinesState extends Equatable {
  /// Creates the state; by default nothing is decided and no point is latched.
  const HomeLinesState({
    this.missed = const Option<MissedLog>.none(),
    this.serial = 0,
    this.asked = false,
    this.tapped = false,
    this.pointPending = false,
    this.askedOn = const Option<CalendarDate>.none(),
    this.install = false,
    this.installMarked = false,
  });

  /// The habit the line asks about; [None] when there is no line.
  final Option<MissedLog> missed;

  /// Counts the lines decided so far, so each one is a new widget identity.
  final int serial;

  /// `asked_on` was written for the line.
  final bool asked;

  /// The line was tapped and its tray has not closed yet; a second tap is ignored.
  final bool tapped;

  /// An evaluation point is latched and waits for Home to be ready.
  final bool pointPending;

  /// The day `asked_on` was last written from here. The habit index is not reloaded by that write,
  /// so a later point the same day reads it from here and asks nothing more (L3).
  final Option<CalendarDate> askedOn;

  /// Whether the one-time install line holds the nudge slot (FR-HO-3); it outranks the missed-log line.
  final bool install;

  /// Whether the install line has been written as seen, so a later reload keeps it on screen.
  final bool installMarked;

  /// Returns a copy with the given fields replaced.
  HomeLinesState copyWith({Option<MissedLog>? missed, int? serial, bool? asked, bool? tapped, bool? pointPending, Option<CalendarDate>? askedOn, bool? install, bool? installMarked}) =>
      HomeLinesState(
        missed: missed ?? this.missed,
        serial: serial ?? this.serial,
        asked: asked ?? this.asked,
        tapped: tapped ?? this.tapped,
        pointPending: pointPending ?? this.pointPending,
        askedOn: askedOn ?? this.askedOn,
        install: install ?? this.install,
        installMarked: installMarked ?? this.installMarked,
      );

  @override
  List<Object?> get props => <Object?>[missed, serial, asked, tapped, pointPending, askedOn, install, installMarked];
}
