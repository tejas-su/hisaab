import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/day_type.dart';
import '../domain/entities/usual_habit.dart';

/// The words Settings uses for a habit: "₹20, weekdays around 10 am" (SPEC FR-SE-2 AC-6, BR-17).
abstract final class UsualWords {
  /// U+202F, the narrow no-break space `intl` puts between the hour and "am".
  static final String _narrowNoBreakSpace = String.fromCharCode(0x202F);

  /// The detail line of [habit], with [amount] as the caller formatted it (glyphs to show,
  /// words to speak) and the hour written for [locale].
  ///
  /// A pooled habit names no kind of day.
  static String detail(AppLocalizations strings, UsualHabit habit, {required String amount, required String locale}) =>
      strings.usualRowDetail(amount, _days(habit), hourWord(habit.window.aroundHour, locale));

  /// The `usualRowDetail` select value for the days [habit] was learned on.
  static String _days(UsualHabit habit) {
    if (habit.pooled) {
      return 'all';
    }
    return switch (habit.dayType) {
      DayType.weekday => 'weekdays',
      DayType.weekend => 'weekends',
    };
  }

  /// The hour as [locale] writes it with a plain space, e.g. "1 pm", for "around {time}".
  static String hourWord(int hour, String locale) => DateFormat.j(locale)
      .format(DateTime(2000, 1, 1, hour))
      // why: intl writes en_IN's "10 am" with a narrow no-break space, a glyph the bundled Mukta
      // font is not known to carry; a plain space reads the same and is what SPEC shows.
      .replaceAll(_narrowNoBreakSpace, ' ');
}
