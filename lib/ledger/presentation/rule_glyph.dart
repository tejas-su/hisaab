import '../../core/design/app_icons.dart';
import '../domain/entities/entry_kind.dart';
import '../domain/entities/recurring_rule.dart';
import 'bill_icon_extensions.dart';

/// The glyph a recurring rule is drawn with.
extension RuleGlyph on RecurringRule {
  /// A saving always shows the piggy bank; a bill shows its picked or name-matched icon (D118, D120).
  AppIconData get glyph => kind == EntryKind.saved ? AppIcons.saving : shownIcon.glyph;
}
