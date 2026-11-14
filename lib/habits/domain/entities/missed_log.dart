import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';
import 'time_window.dart';

/// The one habit the missed-log line asks about: "Spent on Food today?" (SPEC BR-17, FR-HO-3).
final class MissedLog extends Equatable {
  /// Creates the question about [category], whose habit is usually logged in [window] with [amount].
  const MissedLog({required this.category, required this.window, required this.amount});

  /// The category to ask about, as Home shows it now, so its label follows a rename.
  final Category category;

  /// When in the day the habit is usually logged; the line only shows after it.
  final TimeWindow window;

  /// The habit's amount. The line never shows it; the Add tray's pill carries it (FR-HO-3 AC-2).
  final Money amount;

  /// The hour (0–23) for "Usually around 1 pm."; the window's middle, a half hour rounding up.
  int get aroundHour => window.aroundHour;

  @override
  List<Object?> get props => <Object?>[category, window, amount];
}
