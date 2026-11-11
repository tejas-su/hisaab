import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/your_hisaab_bloc.dart';
import '../bloc/your_hisaab_event.dart';
import '../bloc/your_hisaab_state.dart';
import 'backup_copy.dart';
import 'dialog_key.dart';

/// The app's one confirmation dialog: "Replace with this backup?" (SPEC BR-16, FR-SE-4 AC-3).
///
/// It shows the [YourHisaabBloc]'s pending backup, sends *Replace* or *Keep what's here* to it,
/// reads "Bringing back your hisaab…" while the restore runs, and closes itself once nothing is
/// pending. It can't be dismissed while the restore runs.
class RestoreDialog extends StatelessWidget {
  const RestoreDialog({super.key});

  /// The dialog's widest content, so the stacked keys and lines read well on a tablet.
  static const double maxWidth = 360;

  /// The keys' block at normal text size; the busy line takes the same height.
  static const double keysHeight = DialogKey.height * 2 + HisaabSpacing.s;

  /// Shows the dialog over [context] for [bloc]'s pending backup.
  static Future<void> show(BuildContext context, YourHisaabBloc bloc) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext _) => BlocProvider<YourHisaabBloc>.value(value: bloc, child: const RestoreDialog()),
      );

  @override
  Widget build(BuildContext context) => BlocConsumer<YourHisaabBloc, YourHisaabState>(
        // why: only the step from pending to none closes it; the reload after a restore emits a
        // second state with nothing pending, and popping again would close the page beneath.
        listenWhen: (YourHisaabState previous, YourHisaabState current) => _pending(previous) && !_pending(current),
        listener: (BuildContext context, YourHisaabState _) => Navigator.of(context).pop(),
        builder: (BuildContext context, YourHisaabState state) => switch (state) {
          YourHisaabReady(:final pending, :final busy) => pending.match(
              () => const SizedBox.shrink(),
              (PendingRestore restore) => PopScope(
                canPop: false,
                onPopInvokedWithResult: (bool didPop, Object? _) {
                  if (!didPop && busy == YourHisaabBusy.none) {
                    context.read<YourHisaabBloc>().add(const YourHisaabRestoreDismissed());
                  }
                },
                child: _dialog(context, restore, busy: busy == YourHisaabBusy.restoring),
              ),
            ),
          YourHisaabLoading() => const SizedBox.shrink(),
        },
      );

  static bool _pending(YourHisaabState state) => state is YourHisaabReady && state.pending.isSome();

  Widget _dialog(BuildContext context, PendingRestore restore, {required bool busy}) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: context.colors.surface,
      shape: HisaabShapes.squircle(HisaabRadii.card),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(HisaabSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(header: true, child: Text(strings.restoreConfirmTitle, style: text.titleLarge)),
              const SizedBox(height: HisaabSpacing.m),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    '${strings.restoreConfirmFrom(restore.file.entryCount, context.backupDay(restore.file.madeOn))}\n\n'
                    '${strings.restoreConfirmReplaces(restore.entriesHere)}',
                    style: text.bodyMedium?.copyWith(color: context.colors.ink2),
                  ),
                ),
              ),
              const SizedBox(height: HisaabSpacing.xl),
              // why: a minimum, not a fixed height: the keys grow with large text, and the busy line
              // takes their height so the dialog doesn't jump when Replace is tapped.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: keysHeight),
                child: busy ? SizedBox(height: keysHeight, child: _working(context, strings)) : _keys(context, strings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keys(BuildContext context, AppLocalizations strings) {
    final YourHisaabBloc bloc = context.read<YourHisaabBloc>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DialogKey(
          key: const ValueKey<String>('restore-replace'),
          label: strings.restoreConfirmYes,
          strong: true,
          onPressed: () => bloc.add(const YourHisaabRestoreConfirmed()),
        ),
        const SizedBox(height: HisaabSpacing.s),
        DialogKey(
          key: const ValueKey<String>('restore-keep'),
          label: strings.restoreConfirmNo,
          onPressed: () => bloc.add(const YourHisaabRestoreDismissed()),
        ),
      ],
    );
  }

  Widget _working(BuildContext context, AppLocalizations strings) => Semantics(
        liveRegion: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppIcon(AppIcons.busy, color: context.colors.ink2),
            const SizedBox(width: HisaabSpacing.s),
            Flexible(child: Text(strings.restoreWorking, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      );
}
