import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/pinned_keypad_body.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/fix_bloc.dart';
import '../bloc/fix_event.dart';
import '../bloc/fix_state.dart';
import 'fix_guard_panel.dart';
import 'fix_preview_slot.dart';

/// The body of the *Fix my number* sheet: title and preview scroll above the pinned amount, keypad
/// and *Fix it*; in the guard the keypad and key give way to the two answer keys (SPEC FR-FX-2 to 4).
///
/// Needs a [FixBloc] above it. Focus moves to the preview slot in the frame the guard panel is
/// built, because the pressed *Fix it* key disappears under the thumb, and again when the
/// count-only notice appears, so a screen reader reads each once (FR-FX-4 AC-3, AC-6). The key keeps
/// its label while saving; a screen reader hears "Saving" only if the write takes over a second (R12).
class FixKeypadBody extends StatefulWidget {
  const FixKeypadBody({super.key, required this.state});

  final FixState state;

  @override
  State<FixKeypadBody> createState() => _FixKeypadBodyState();
}

class _FixKeypadBodyState extends State<FixKeypadBody> {
  final FocusNode _slotFocus = FocusNode(debugLabel: 'fix-slot');
  Timer? _savingTimer;
  bool _speakSaving = false;

  /// How long a write runs before a screen reader is told it is saving (copy deck 41, R12).
  static const Duration savingAnnouncementDelay = Duration(seconds: 1);

  @override
  void didUpdateWidget(FixKeypadBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _watchSaving(oldWidget.state, widget.state);
    if (_needsFocus(oldWidget.state, widget.state)) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          _slotFocus.requestFocus();
        }
      });
    }
  }

  static bool _isSaving(FixState state) => state is FixReady && state.saving;

  // why: the write is normally under 100 ms and the sheet closes, so "Saving" would only talk over the
  // focus-return speech; it is spoken only if the write is still running after a second.
  void _watchSaving(FixState before, FixState after) {
    if (!_isSaving(before) && _isSaving(after)) {
      _savingTimer = Timer(savingAnnouncementDelay, _announceSaving);
    } else if (!_isSaving(after)) {
      _savingTimer?.cancel();
      _speakSaving = false;
    }
  }

  // why: a live region speaks when its label changes, which is how a screen reader hears "Saving".
  void _announceSaving() {
    if (mounted && _isSaving(widget.state)) {
      setState(() => _speakSaving = true);
    }
  }

  static bool _needsFocus(FixState before, FixState after) {
    if (after is! FixReady) {
      return false;
    }
    final bool guardOpened = after.guard.isSome() && !(before is FixReady && before.guard.isSome());
    final bool countOnlyShown = after.notice == FixNotice.countOnly && !(before is FixReady && before.notice == FixNotice.countOnly);
    return guardOpened || countOnlyShown;
  }

  @override
  void dispose() {
    _savingTimer?.cancel();
    _slotFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final FixBloc bloc = context.read<FixBloc>();
    final FixState state = widget.state;
    final bool isWeek = state is FixReady && state.summary.cycle.isWeek;
    final String period = isWeek ? 'week' : 'month';
    return PinnedKeypadBody(
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(header: true, child: Text(strings.fixTitle(period), style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: HisaabSpacing.m),
          FixPreviewSlot(state: state, period: period, focusNode: _slotFocus, onRetry: () => bloc.add(const FixLoadRequested())),
          Semantics(container: true, liveRegion: true, label: _speakSaving ? strings.fixSavingSpoken : '', child: const SizedBox(width: 1, height: 1)),
          const SizedBox(height: HisaabSpacing.m),
        ],
      ),
      figure: AmountDisplay(
        amount: Money.fromMajor(state is FixReady ? state.typed.getOrElse(() => 0) : 0),
        rejections: state is FixReady ? state.rejections : 0,
      ),
      controls: (BuildContext context, double keyHeight) => state is FixReady && state.guard.isSome()
          ? _guard(context, bloc, state)
          : _keypad(context, bloc, state, keyHeight),
    );
  }

  Widget _guard(BuildContext context, FixBloc bloc, FixReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final Money gap = state.preview is FixChange ? (state.preview as FixChange).gap : Money.zero;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
      child: FixGuardPanel(
        gap: context.money.format(gap),
        spokenGap: strings.spokenAmount(context.money.digits(gap)),
        onNo: () => bloc.add(const FixGuardAnswered(yes: false)),
        onYes: () => bloc.add(const FixGuardAnswered(yes: true)),
      ),
    );
  }

  Widget _keypad(BuildContext context, FixBloc bloc, FixState state, double keyHeight) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final FixReady? ready = state is FixReady ? state : null;
    final FixPreview? preview = ready?.preview;
    final bool canFix = ready != null && !ready.saving && preview is FixChange;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Keypad(
          keyHeight: keyHeight,
          onKey: (String key) => bloc.add(FixKeyPressed(key)),
          onBackspace: () => bloc.add(const FixBackspacePressed()),
          onClear: () => bloc.add(const FixCleared()),
        ),
        const SizedBox(height: HisaabSpacing.m),
        SignalKey(
          key: const ValueKey<String>('fix-action'),
          label: strings.fixAction,
          semanticHint: canFix ? null : _whyOff(strings, preview),
          onPressed: canFix ? () => bloc.add(const FixSavePressed()) : null,
        ),
      ],
    );
  }

  // why: a disabled key says why to a screen reader (FR-KS-4 AC-5): nothing typed, or nothing to fix.
  static String? _whyOff(AppLocalizations strings, FixPreview? preview) => switch (preview) {
        FixEqual() || FixClose() => strings.fixActionHintNothing,
        _ => strings.typeAmountFirst,
      };
}
