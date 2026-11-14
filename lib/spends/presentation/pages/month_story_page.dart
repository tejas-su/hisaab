import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_theme.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/month_story_bloc.dart';
import '../bloc/month_story_event.dart';
import '../bloc/month_story_state.dart';
import '../cycle_label.dart';
import '../widgets/month_story_view.dart';

/// The month story route (SPEC FR-SP-7): always in the dark theme's tokens, a centred column no
/// wider than [maxWidth] (AC-4, AC-7). Needs a [MonthStoryBloc] above it; closes itself when the
/// cycle no longer has a story. [today] names cycles; [onAskAi] opens Ask AI for a cycle (AC-8).
class MonthStoryPage extends StatelessWidget {
  const MonthStoryPage({super.key, required this.today, required this.onAskAi});

  final CalendarDate today;
  final ValueChanged<PayCycle> onAskAi;

  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) => Theme(
        data: HisaabTheme.dark(),
        child: Builder(
          builder: (BuildContext context) => Scaffold(
            backgroundColor: context.colors.background,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: BlocConsumer<MonthStoryBloc, MonthStoryState>(
                    listenWhen: (MonthStoryState _, MonthStoryState next) => next is MonthStoryGone,
                    listener: (BuildContext context, MonthStoryState _) => Navigator.of(context).maybePop(),
                    builder: _body,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _body(BuildContext context, MonthStoryState state) => switch (state) {
        MonthStoryReady(:final story) => MonthStoryView(
            story: story,
            cycleLabel: _label(context, story.cycle),
            previousLabel: _label(context, story.previous),
            onAskAi: () => onAskAi(story.cycle),
            onDone: () => Navigator.of(context).maybePop(),
          ),
        MonthStoryFailed() => _failed(context),
        MonthStoryLoading() || MonthStoryGone() => const Align(alignment: AlignmentDirectional.topStart, child: _BackOnly()),
      };

  Widget _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _BackOnly(),
        Padding(
          padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
              const SizedBox(height: HisaabSpacing.m),
              HisaabChip(label: strings.tryAgain, onPressed: () => context.read<MonthStoryBloc>().add(const MonthStoryLoadRequested())),
            ],
          ),
        ),
      ],
    );
  }

  String _label(BuildContext context, PayCycle cycle) =>
      CycleLabel.of(cycle, locale: Localizations.localeOf(context).toString(), today: today);
}

/// Back alone, while the story loads or after it failed.
class _BackOnly extends StatelessWidget {
  const _BackOnly();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, 0, 0),
        child: HisaabBackButton(),
      );
}
