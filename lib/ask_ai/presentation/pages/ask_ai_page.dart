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
import '../widgets/ask_ai_controls.dart';
import '../widgets/ask_ai_header.dart';
import '../widgets/ask_ai_send_panel.dart';

/// Ask AI: pick a goal and period, check the exact prompt, then hand it off (SPEC FR-AI).
///
/// Needs an [AskAiBloc] above it. In one pane everything scrolls together; with two panes or
/// a tabletop fold the choices and the preview sit on either side, never across the fold.
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
    final List<Widget> choices = <Widget>[const AskAiHeader(), const SizedBox(height: HisaabSpacing.l), ..._choices(context, state)];
    final List<Widget> send = _send(state);
    return switch (context.layout.panes) {
      SinglePane(:final Rect content) => <Widget>[
        Pane(rect: content, windowSize: window, child: _scroll(<Widget>[...choices, ...send])),
      ],
      SideBySidePanes(:final Rect primary, :final Rect secondary) => <Widget>[
        Pane(rect: primary, windowSize: window, child: _scroll(choices)),
        Pane(rect: secondary, windowSize: window, child: _scroll(send)),
      ],
      TabletopPanes(:final Rect top, :final Rect bottom) => <Widget>[
        Pane(rect: top, windowSize: window, child: _scroll(choices)),
        Pane(rect: bottom, windowSize: window, child: _scroll(send)),
      ],
    };
  }

  List<Widget> _choices(BuildContext context, AskAiState state) => switch (state) {
    AskAiLoading() => const <Widget>[],
    AskAiFailed() => _failed(context),
    AskAiReady(:final choice) => <Widget>[AskAiControls(choice: choice)],
  };

  List<Widget> _send(AskAiState state) => switch (state) {
    AskAiReady() => <Widget>[const SizedBox(height: HisaabSpacing.l), AskAiSendPanel(ready: state)],
    AskAiLoading() || AskAiFailed() => const <Widget>[],
  };

  Widget _scroll(List<Widget> children) => ListView(
    padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.m, HisaabSpacing.gutter, HisaabSpacing.xl),
    children: children,
  );

  List<Widget> _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return <Widget>[
      Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.colors.ink2)),
      const SizedBox(height: HisaabSpacing.m),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: HisaabChip(label: strings.tryAgain, onPressed: () => context.read<AskAiBloc>().add(const AskAiLoadRequested())),
      ),
    ];
  }

  void _showCopied(BuildContext context) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).askCopiedToast)));
}
