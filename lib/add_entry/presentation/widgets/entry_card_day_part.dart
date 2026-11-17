import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';
import 'entry_card_words.dart';

/// The entry card's days: the last four as pills, the entry's own picked, and *Earlier* for the
/// date picker within BR-10's limits (SPEC FR-AD-8 AC-6).
class EntryCardDayPart extends StatelessWidget {
  const EntryCardDayPart({super.key, required this.form});

  final EntryCardForm form;

  static const int _pills = 4;

  @override
  Widget build(BuildContext context) {
    final EntryCardBloc bloc = context.read<EntryCardBloc>();
    final List<CalendarDate> days = List<CalendarDate>.generate(_pills, (int back) => form.today.addDays(-back))
        .where((CalendarDate day) => !day.isBefore(form.earliestDate))
        .toList();
    return Wrap(
      spacing: HisaabSpacing.s,
      runSpacing: HisaabSpacing.s,
      children: <Widget>[
        for (final CalendarDate day in days)
          HisaabChip(
            key: ValueKey<String>('entry-card-day-${day.toIso()}'),
            onSurface: true,
            label: EntryCardWords.day(context, day, form.today),
            selected: day == form.date,
            onPressed: () => bloc.add(EntryCardDayPicked(day)),
          ),
        HisaabChip(
          key: const ValueKey<String>('entry-card-earlier'),
          onSurface: true,
          label: AppLocalizations.of(context).entryCardEarlier,
          selected: !days.contains(form.date),
          onPressed: () => _pick(context, bloc),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, EntryCardBloc bloc) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _asDateTime(form.date),
      firstDate: _asDateTime(form.earliestDate),
      lastDate: _asDateTime(form.today),
      builder: (BuildContext context, Widget? child) => Theme(
        // why: the typed-date field sits on the dialog's surface, so it keeps the hairline step (D100).
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(fillColor: context.colors.hairline),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      bloc.add(EntryCardDayPicked(CalendarDate.fromDateTime(picked)));
    }
  }

  static DateTime _asDateTime(CalendarDate day) => DateTime(day.year, day.month, day.day);
}
