import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The *Today ▾* chip: Today, Yesterday or a picked date within the allowed range (BR-10).
class DateChip extends StatelessWidget {
  const DateChip({super.key, required this.date, required this.today, required this.earliest, required this.onChanged});

  final CalendarDate date;
  final CalendarDate today;
  final CalendarDate earliest;
  final ValueChanged<CalendarDate> onChanged;

  @override
  Widget build(BuildContext context) => HisaabChip(
        key: const ValueKey<String>('date-chip'),
        onSurface: true,
        label: _label(context),
        icon: AppIcons.calendar,
        trailingIcon: AppIcons.dropdown,
        onPressed: () => _openChoices(context),
      );

  String _label(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    if (date == today) {
      return strings.today;
    }
    if (date == today.addDays(-1)) {
      return strings.yesterday;
    }
    return DateFormat('d MMM', Localizations.localeOf(context).toString()).format(_asDateTime(date));
  }

  void _openChoices(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: HisaabShapes.trayTop(),
      builder: (BuildContext sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              HisaabChip(
                key: const ValueKey<String>('date-today'),
                onSurface: true,
                label: strings.today,
                expand: true,
                onPressed: () => _choose(sheet, today),
              ),
              const SizedBox(height: HisaabSpacing.s),
              HisaabChip(
                key: const ValueKey<String>('date-yesterday'),
                onSurface: true,
                label: strings.yesterday,
                expand: true,
                onPressed: () => _choose(sheet, today.addDays(-1)),
              ),
              const SizedBox(height: HisaabSpacing.s),
              HisaabChip(
                key: const ValueKey<String>('date-pick'),
                onSurface: true,
                label: strings.pickDate,
                expand: true,
                onPressed: () => _pick(sheet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _choose(BuildContext sheet, CalendarDate day) {
    Navigator.of(sheet).pop();
    onChanged(day);
  }

  void _pick(BuildContext sheet) {
    final NavigatorState navigator = Navigator.of(sheet);
    showDatePicker(
      context: sheet,
      initialDate: _asDateTime(date),
      firstDate: _asDateTime(earliest),
      lastDate: _asDateTime(today),
      builder: _onSurfaceFields,
    ).then((DateTime? picked) {
      navigator.pop();
      if (picked != null) {
        onChanged(CalendarDate.fromDateTime(picked));
      }
    });
  }

  // why: the picker's typed-date field sits on the dialog's surface, where the theme's control fill
  // would vanish in light; it keeps the hairline step, like every control on a surface (D100).
  static Widget _onSurfaceFields(BuildContext context, Widget? child) {
    final ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(inputDecorationTheme: theme.inputDecorationTheme.copyWith(fillColor: context.colors.hairline)),
      child: child ?? const SizedBox.shrink(),
    );
  }

  static DateTime _asDateTime(CalendarDate day) => DateTime(day.year, day.month, day.day);
}
