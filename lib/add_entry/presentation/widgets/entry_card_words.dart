import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/time/calendar_date.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/entry_card_state.dart';

/// The words the entry card and its Undo bar use for a form's values (SPEC FR-AD-8, BR-10).
abstract final class EntryCardWords {
  /// "Today", "Yesterday", or "24 Oct", as the tray's date chip says it.
  static String day(BuildContext context, CalendarDate date, CalendarDate today) {
    final AppLocalizations strings = AppLocalizations.of(context);
    if (date == today) {
      return strings.today;
    }
    if (date == today.addDays(-1)) {
      return strings.yesterday;
    }
    return DateFormat('d MMM', Localizations.localeOf(context).toString()).format(DateTime(date.year, date.month, date.day));
  }

  /// The category's name in the app's language, or empty when [id] is unknown.
  static String category(BuildContext context, List<Category> categories, int id) {
    final Category? found = categories.where((Category c) => c.id == id).firstOrNull;
    return found == null ? '' : found.labelIn(AppLocalizations.of(context));
  }

  /// The Undo bar's message for [edit]: the one change it made, or how many (BR-10). [amount]
  /// formats money; [today] names a day "today" or "yesterday".
  static String edit(
    BuildContext context,
    EntryEdit edit, {
    required List<Category> categories,
    required CalendarDate today,
    required String Function(Entry entry) amount,
  }) {
    final AppLocalizations strings = AppLocalizations.of(context);
    if (edit.changes.length > 1) {
      return strings.entryEditMany(edit.changes.length);
    }
    final Entry saved = edit.saved;
    return switch (edit.changes.single) {
      CardChange.amount => strings.entryEditChangedTo(amount(saved)),
      CardChange.category => strings.entryEditMovedTo(category(context, categories, saved.categoryId)),
      CardChange.day => strings.entryEditMovedTo(_inSentence(day(context, saved.date, today), saved.date, today)),
      CardChange.note => saved.note == null ? strings.entryEditNoteRemoved : strings.entryEditNoteChanged,
    };
  }

  // why: "Moved to yesterday" reads as a sentence; a date like "24 Oct" keeps its capital.
  static String _inSentence(String word, CalendarDate date, CalendarDate today) =>
      date == today || date == today.addDays(-1) ? word.toLowerCase() : word;
}
