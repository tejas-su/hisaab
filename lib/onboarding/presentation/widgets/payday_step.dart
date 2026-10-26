import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/onboarding_step.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../../../core/widgets/day_of_month_grid.dart';
import 'step_header.dart';
import 'weekday_picker.dart';

/// Step 2: "When does it come?" with five big choices; a choice moves on (SPEC FR-ON-3).
///
/// The choices sit at the bottom, in thumb reach. *Pick a date* and *Every week* first show
/// their own picker.
class PaydayStep extends StatelessWidget {
  const PaydayStep({super.key, required this.state});

  final OnboardingInProgress state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final OnboardingBloc bloc = context.read<OnboardingBloc>();
    final (String question, Widget controls) = switch (state.picker) {
      PaydayPicker.none => (strings.paydayQuestion, _choices(strings, bloc)),
      PaydayPicker.dayOfMonth => (
          strings.pickPaydayQuestion,
          DayOfMonthGrid(onDay: (int day) => bloc.add(OnboardingPayRuleChosen(MonthlyOnDay(day)))),
        ),
      PaydayPicker.weekday => (
          strings.pickWeekdayQuestion,
          WeekdayPicker(onWeekday: (int weekday) => bloc.add(OnboardingPayRuleChosen(WeeklyOn(weekday)))),
        ),
    };
    return AdaptiveSplit(
      header: StepHeader(step: OnboardingStep.payday, question: question, hint: strings.paydayHint),
      controls: controls,
    );
  }

  Widget _choices(AppLocalizations strings, OnboardingBloc bloc) {
    final List<(String, String, VoidCallback)> choices = <(String, String, VoidCallback)>[
      ('first', strings.payFirstOfMonth, () => bloc.add(const OnboardingPayRuleChosen(MonthlyOnDay(1)))),
      ('last', strings.payLastDay, () => bloc.add(const OnboardingPayRuleChosen(LastDayOfMonth()))),
      ('date', strings.payPickDate, () => bloc.add(const OnboardingPickerOpened(PaydayPicker.dayOfMonth))),
      ('week', strings.payEveryWeek, () => bloc.add(const OnboardingPickerOpened(PaydayPicker.weekday))),
      ('changes', strings.payItChanges, () => bloc.add(const OnboardingPayRuleChosen(IrregularIncome()))),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (String id, String label, VoidCallback onPressed) in choices)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.s),
            child: HisaabChip(key: ValueKey<String>('payday-$id'), label: label, onPressed: onPressed, expand: true),
          ),
      ],
    );
  }
}
