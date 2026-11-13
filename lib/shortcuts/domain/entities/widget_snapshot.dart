import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../settings/settings.dart';

/// Everything the home-screen widget draws, written by the app after every change (SPEC FR-WG-5,
/// widget spec §4). Native code only picks today's row and draws it: every word and amount here
/// is already worded and formatted.
final class WidgetSnapshot extends Equatable {
  const WidgetSnapshot({required this.writtenAt, required this.look, required this.strings, required this.rows});

  /// When the app wrote it.
  final DateTime writtenAt;

  /// The app's *Look* (FR-SE-3); the widget follows it, not only the phone (FR-WG-2).
  final ThemeChoice look;

  /// The words that are the same on every day.
  final WidgetStrings strings;

  /// One row per day, today first, to the end of the cycle after this one.
  final List<WidgetDay> rows;

  @override
  List<Object?> get props => <Object?>[writtenAt, look, strings, rows];
}

/// The widget's words that don't change from day to day.
final class WidgetStrings extends Equatable {
  const WidgetStrings({
    required this.title,
    required this.add,
    required this.addSpoken,
    required this.setUp,
    required this.setUpBody,
  });

  /// "Safe to spend today".
  final String title;

  /// "Add", on the 2×2's wide key.
  final String add;

  /// "Add a spend", what TalkBack reads for the Add key.
  final String addSpoken;

  /// "Set up", the key when there is no income yet.
  final String setUp;

  /// "Set up hisaab to see what's safe to spend today."
  final String setUpBody;

  @override
  List<Object?> get props => <Object?>[title, add, addSpoken, setUp, setUpBody];
}

/// How a day looks on the widget, in SPEC BR-5's order; [setUp] is *No income* (FR-WG-3).
enum WidgetDayState { onTrack, slowDown, overToday, overCycle, setUp }

/// One day of the widget: the hero in miniature as it will stand on [date] (FR-WG-1, FR-WG-3).
final class WidgetDay extends Equatable {
  const WidgetDay({
    required this.date,
    required this.state,
    required this.hero,
    required this.heroMuted,
    required this.over,
    required this.glance,
    required this.range,
    required this.days,
    required this.daysLeft,
    required this.flag,
    required this.bar,
    required this.dots,
    required this.spoken,
  });

  final CalendarDate date;
  final WidgetDayState state;

  /// The amount, e.g. "₹1,430"; "₹0" when over.
  final String hero;

  /// The amount is drawn quieter (`displayInk2`) when over.
  final bool heroMuted;

  /// "₹220 over today" or "₹3,200 over" next to the amount, in the over states.
  final Option<String> over;

  /// The 2×1's line under the amount: "left today", "₹220 over today" or "Over by ₹3,200".
  final String glance;

  /// The range line (BR-7), lead and detail joined, e.g. "Lasts till payday · about ₹9,300 spare".
  final String range;

  /// "9 days", beside the 4×2's range line.
  final String days;

  /// "9 days left", on the 2×2.
  final String daysLeft;

  /// The payday flag's date, e.g. "4 Nov".
  final String flag;
  final WidgetBar bar;
  final WidgetDots dots;

  /// The one sentence TalkBack reads for the whole widget (FR-WG-8).
  final String spoken;

  @override
  List<Object?> get props => <Object?>[date, state, hero, heroMuted, over, glance, range, days, daysLeft, flag, bar, dots, spoken];
}

/// How today's bar draws what's left (BR-6): solid, outlined, or none with a hatch past the tick.
enum WidgetBarStyle { onTrack, slowDown, over }

/// Today's bar as shares of its span, from the start edge (BR-6), without names.
final class WidgetBar extends Equatable {
  const WidgetBar({required this.style, required this.left, required this.bites, required this.tick});

  final WidgetBarStyle style;

  /// What's left of today's share, 0–1.
  final double left;

  /// Today's spends in the order saved, each 0–1; the first sits at the end edge. Empty on later days.
  final List<double> bites;

  /// Where today's share ends when more was spent; [None] when not over.
  final Option<double> tick;

  @override
  List<Object?> get props => <Object?>[style, left, bites, tick];
}

/// How the days rail draws today's dot and the later ones (BR-5).
enum WidgetDotsStyle { onTrack, slowDown, overToday, overCycle }

/// The days rail: one dot per day left, today's first (BR-6).
final class WidgetDots extends Equatable {
  const WidgetDots({required this.count, required this.style});

  /// Days left, today included; at least 1.
  final int count;
  final WidgetDotsStyle style;

  @override
  List<Object?> get props => <Object?>[count, style];
}
