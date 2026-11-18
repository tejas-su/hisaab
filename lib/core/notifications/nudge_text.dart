import '../../l10n/gen/app_localizations.dart';
import 'nudge_notice.dart';

/// The words of a daily nudge (BR-22.7): up to three phrasings rotated by date, never an amount
/// or a note. Pure, so the text of any day can be checked without the notification plugin.
abstract final class NudgeText {
  static const int _phrasings = 3;
  static final DateTime _epoch = DateTime.utc(2020);

  /// Which phrasing (0 to 2) the nudge at [at] uses: a function of its local calendar date, so
  /// it is stable all day and steps by one each day.
  static int variantFor(DateTime at) =>
      DateTime.utc(at.year, at.month, at.day).difference(_epoch).inDays % _phrasings;

  /// The title and body of [notice], in [strings]: the category phrasing when it names one,
  /// the general phrasing otherwise.
  static ({String title, String body}) of(AppLocalizations strings, NudgeNotice notice) {
    final int variant = variantFor(notice.at);
    return notice.categoryName.match(
      () => _general(strings, variant),
      (String category) => (title: _titled(strings, variant, category), body: _body(strings, variant)),
    );
  }

  static String _titled(AppLocalizations strings, int variant, String category) => switch (variant) {
        0 => strings.nudgeTitle1(category),
        1 => strings.nudgeTitle2(category),
        _ => strings.nudgeTitle3(category),
      };

  static String _body(AppLocalizations strings, int variant) => switch (variant) {
        0 => strings.nudgeBody1,
        1 => strings.nudgeBody2,
        _ => strings.nudgeBody3,
      };

  static ({String title, String body}) _general(AppLocalizations strings, int variant) => switch (variant) {
        0 => (title: strings.nudgeGeneralTitle1, body: strings.nudgeGeneralBody1),
        1 => (title: strings.nudgeGeneralTitle2, body: strings.nudgeGeneralBody2),
        _ => (title: strings.nudgeGeneralTitle3, body: strings.nudgeGeneralBody3),
      };
}
