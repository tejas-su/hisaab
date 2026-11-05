import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/bill_draft.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/onboarding_step.dart';
import '../../domain/entities/setup_labels.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import 'step_header.dart';

/// Step 3: "Any fixed bills?" with a chip per common bill and Skip always visible (FR-ON-4).
///
/// The finish key reads Skip until a bill is added, then Done. While [busy], it is disabled.
class BillsStep extends StatelessWidget {
  const BillsStep({super.key, required this.draft, this.busy = false, this.saveFailed = false});

  final OnboardingDraft draft;
  final bool busy;
  final bool saveFailed;

  /// The localised names for the rules onboarding creates.
  static SetupLabels labelsOf(AppLocalizations strings) => SetupLabels(
        income: strings.categoryName('salary'),
        bills: <BillKind, String>{for (final BillKind kind in BillKind.values) kind: strings.billName(kind.name)},
        startingGuess: strings.startingGuessNote,
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final OnboardingBloc bloc = context.read<OnboardingBloc>();
    final Map<BillKind, BillDraft> added = <BillKind, BillDraft>{for (final BillDraft bill in draft.bills) bill.kind: bill};
    return AdaptiveSplit(
      header: StepHeader(
        step: OnboardingStep.bills,
        question: strings.billsQuestion,
        hint: strings.billsHint,
        children: <Widget>[
          if (saveFailed) ...<Widget>[
            const SizedBox(height: HisaabSpacing.l),
            Text(strings.couldntSave, style: Theme.of(context).textTheme.titleMedium),
          ],
        ],
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: HisaabSpacing.s,
            runSpacing: HisaabSpacing.s,
            children: <Widget>[
              // why: onboarding asks for a bill's amount once and posts it every month, so only the
              // fixed bills are offered; changing and card bills live in Settings (D125).
              for (final BillKind kind in BillKind.values.where((BillKind kind) => kind.amountMode == AmountMode.fixed))
                HisaabChip(
                  key: ValueKey<String>('bill-${kind.name}'),
                  label: strings.billName(kind.name),
                  icon: added.containsKey(kind) ? AppIcons.check : AppIcons.add,
                  detail: _detail(context, strings, added[kind]),
                  selected: added.containsKey(kind),
                  onPressed: () => bloc.add(OnboardingBillOpened(kind)),
                ),
            ],
          ),
          const SizedBox(height: HisaabSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('finish-onboarding'),
              label: draft.bills.isEmpty ? strings.skip : strings.done,
              onPressed: busy ? null : () => bloc.add(OnboardingFinishRequested(labelsOf(strings))),
            ),
          ),
        ],
      ),
    );
  }

  static String? _detail(BuildContext context, AppLocalizations strings, BillDraft? bill) =>
      bill == null ? null : strings.billDetail(context.money.format(bill.amount), bill.dueDay);
}
