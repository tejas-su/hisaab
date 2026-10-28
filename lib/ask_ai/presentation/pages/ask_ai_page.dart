import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/pane.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/ask_ai_bloc.dart';
import '../bloc/ask_ai_event.dart';
import '../bloc/ask_ai_state.dart';
import '../widgets/ask_ai_actions.dart';
import '../widgets/ask_ai_controls.dart';
import '../widgets/ask_ai_header.dart';
import '../widgets/ask_ai_preview_card.dart';

/// Ask AI: pick a goal and period, check the exact prompt, then hand it off (SPEC FR-AI).
///
/// Needs an [AskAiBloc] above it. The header stays fixed and the actions stay pinned to the
/// bottom; only the cards between them scroll. With two panes or a tabletop fold, the choices
/// and the preview sit on either side, never across the fold (D67).
class AskAiPage extends StatelessWidget {
  const AskAiPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocConsumer<AskAiBloc, AskAiState>(
      listenWhen: (AskAiState previous, AskAiState current) =>
          previous is AskAiReady && current is AskAiReady && current.toasts > previous.toasts,
      listener: (BuildContext context, AskAiState _) => _showCopied(context),
      builder: (BuildContext context, AskAiState state) => Stack(children: _panes(context, state)),
    ),
  );

  List<Widget> _panes(BuildContext context, AskAiState state) {
    // why: Pane places its child by window coordinates, as the app shell does.
    final Size window = MediaQuery.sizeOf(context);
    final List<Widget> choices = _choices(context, state);
    final List<Widget> preview = <Widget>[if (state is AskAiReady) AskAiPreviewCard(ready: state)];
    return switch (context.layout.panes) {
      SinglePane(:final Rect content) => <Widget>[
        Pane(
          rect: content,
          windowSize: window,
          child: _column(header: true, scrolling: <Widget>[...choices, ...preview], state: state),
        ),
      ],
      SideBySidePanes(:final Rect primary, :final Rect secondary) => <Widget>[
        Pane(
          rect: primary,
          windowSize: window,
          child: _column(header: true, scrolling: choices),
        ),
        Pane(
          rect: secondary,
          windowSize: window,
          child: _column(scrolling: preview, state: state),
        ),
      ],
      TabletopPanes(:final Rect top, :final Rect bottom) => <Widget>[
        Pane(
          rect: top,
          windowSize: window,
          child: _column(header: true, scrolling: choices),
        ),
        Pane(
          rect: bottom,
          windowSize: window,
          child: _column(scrolling: preview, state: state),
        ),
      ],
    };
  }

  /// A fixed [header] on top, the [scrolling] cards, and the actions pinned at the bottom when
  /// [state] is ready.
  Widget _column({bool header = false, required List<Widget> scrolling, AskAiState? state}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (header)
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, HisaabSpacing.s),
          child: AskAiHeader(),
        ),
      Expanded(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.l),
          children: <Widget>[
            for (final (int index, Widget card) in scrolling.indexed) ...<Widget>[
              if (index > 0) const SizedBox(height: HisaabSpacing.l),
              card,
            ],
          ],
        ),
      ),
      if (state is AskAiReady)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.l),
          child: AskAiActions(canSend: state.choice.canSend, needsPaste: state.needsPaste),
        ),
    ],
  );

  List<Widget> _choices(BuildContext context, AskAiState state) => switch (state) {
    AskAiLoading() => const <Widget>[],
    AskAiFailed() => <Widget>[_failed(context)],
    AskAiReady(:final choice, :final input) => <Widget>[AskAiControls(choice: choice, input: input)],
  };

  Widget _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.m),
        HisaabChip(label: strings.tryAgain, onPressed: () => context.read<AskAiBloc>().add(const AskAiLoadRequested())),
      ],
    );
  }

  void _showCopied(BuildContext context) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).askCopiedToast)));
}
