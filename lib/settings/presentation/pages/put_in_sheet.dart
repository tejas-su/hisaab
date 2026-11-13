import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/pinned_keypad_body.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/put_in_extra_bloc.dart';
import '../bloc/put_in_extra_event.dart';
import '../bloc/put_in_extra_state.dart';
import 'bill_sheet.dart';

/// *Put in extra* (SPEC FR-SE-1, D120): a keypad in the bill sheet's route for a one-off saving
/// today, capped at what is left, with a line saying what it does to the days left. Open it
/// with [show].
class PutInSheet extends StatelessWidget {
  const PutInSheet({super.key});

  /// Opens the sheet for [bloc] over [context]; the sheet closes [bloc] when it goes, and the
  /// future completes after its exit animation.
  static Future<void> show(BuildContext context, PutInExtraBloc bloc) async {
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext _) => BlocProvider<PutInExtraBloc>(create: (BuildContext _) => bloc, child: const PutInSheet()),
    );
    await Navigator.of(context).push(route);
    await route.completed;
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<PutInExtraBloc, PutInExtraState>(
    listenWhen: (PutInExtraState _, PutInExtraState current) => current is PutInExtraDone,
    listener: (BuildContext context, PutInExtraState _) => Navigator.of(context).pop(),
    buildWhen: (PutInExtraState _, PutInExtraState current) => current is! PutInExtraDone,
    builder: (BuildContext context, PutInExtraState state) => switch (state) {
      PutInExtraReady() => _keypad(context, state),
      PutInExtraFailed() => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.gutter),
        child: Text(AppLocalizations.of(context).loadFailed, style: Theme.of(context).textTheme.bodyLarge),
      ),
      PutInExtraLoading() || PutInExtraDone() => const SizedBox.shrink(),
    },
  );

  Widget _keypad(BuildContext context, PutInExtraReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final PutInExtraBloc bloc = context.read<PutInExtraBloc>();
    final TextStyle? line = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    final bool canSave = state.rupees > 0 && !state.saving && !state.nothingLeft;
    return PinnedKeypadBody(
      figure: AmountDisplay(amount: Money.fromMajor(state.rupees), rejections: state.rejections),
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(strings.putInQuestion, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: HisaabSpacing.s),
          Semantics(
            liveRegion: true,
            child: Text(_line(context, state), key: const ValueKey<String>('put-in-line'), style: line),
          ),
          if (state.saveFailed) Text(strings.couldntSave, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: HisaabSpacing.s),
        ],
      ),
      controls: (BuildContext context, double keyHeight) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Keypad(
            keyHeight: keyHeight,
            onKey: (String key) => bloc.add(PutInExtraKeyPressed(key)),
            onBackspace: () => bloc.add(const PutInExtraBackspacePressed()),
            onClear: () => bloc.add(const PutInExtraCleared()),
          ),
          const SizedBox(height: HisaabSpacing.m),
          SignalKey(
            key: const ValueKey<String>('put-in-save'),
            label: strings.save,
            onPressed: canSave ? () => bloc.add(const PutInExtraSavePressed()) : null,
          ),
        ],
      ),
    );
  }

  // why: a month-end cycle has no payday, so the line says "month end", as the hero does (D116).
  static String _line(BuildContext context, PutInExtraReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String end = state.summary.endsAtMonthEnd ? 'monthEnd' : 'payday';
    if (state.nothingLeft) {
      return strings.putInNothingLeft;
    }
    return switch (state.preview.toNullable()) {
      EachDayLess(:final Money less) => strings.putInEachDayLess(end, context.money.format(less)),
      PaydayTomorrow() => strings.putInLastDay(end),
      null => '',
    };
  }
}
