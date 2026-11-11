import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../backup/backup.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'settings_row.dart';

/// Settings' *Your hisaab* group: *Back up*, *Restore*, *Undo restore* while it lasts, the
/// no-password note, and *Delete everything* in a card of its own (SPEC FR-SE-4 AC-1..3, D139).
///
/// Needs a [YourHisaabBloc] above it. It opens the restore dialog when a checked file waits;
/// [YourHisaabNotices] shows the messages.
class YourHisaabGroup extends StatelessWidget {
  const YourHisaabGroup({super.key, required this.today, required this.onOpenDelete});

  final CalendarDate today;
  final VoidCallback onOpenDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return BlocConsumer<YourHisaabBloc, YourHisaabState>(
      // why: only a newly checked file opens the dialog; later states while it is open must not.
      listenWhen: (YourHisaabState previous, YourHisaabState current) => !_pending(previous) && _pending(current),
      listener: (BuildContext context, YourHisaabState _) => RestoreDialog.show(context, context.read<YourHisaabBloc>()),
      builder: (BuildContext context, YourHisaabState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _card(context, _rows(context, strings, state)),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.xs, HisaabSpacing.s, HisaabSpacing.xs, HisaabSpacing.xl),
            child: Text(strings.backUpNoLock, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2)),
          ),
          _card(context, <Widget>[
            SettingsRow(
              key: const ValueKey<String>('open-delete-everything'),
              icon: AppIcons.delete,
              label: strings.deleteAllRow,
              detail: strings.deleteAllRowHint,
              onTap: onOpenDelete,
            ),
          ]),
        ],
      ),
    );
  }

  List<Widget> _rows(BuildContext context, AppLocalizations strings, YourHisaabState state) {
    final YourHisaabReady? ready = state is YourHisaabReady ? state : null;
    final YourHisaabBusy busy = ready?.busy ?? YourHisaabBusy.none;
    final bool idle = ready != null && busy == YourHisaabBusy.none;
    final YourHisaabBloc bloc = context.read<YourHisaabBloc>();
    final RestoreUndo? undo = ready?.status.undo.toNullable();
    return <Widget>[
      SettingsRow(
        key: const ValueKey<String>('back-up'),
        icon: AppIcons.backUp,
        label: strings.backUpRow,
        detail: busy == YourHisaabBusy.backingUp
            ? strings.backUpBusy
            : (ready == null ? null : context.lastBackup(ready.status.lastBackedUp, today)),
        busy: busy == YourHisaabBusy.backingUp,
        onTap: idle ? () => bloc.add(const YourHisaabBackUpRequested()) : null,
      ),
      _divider(context),
      SettingsRow(
        key: const ValueKey<String>('restore'),
        icon: AppIcons.restore,
        label: strings.restoreRow,
        detail: busy == YourHisaabBusy.checking ? strings.restoreChecking : strings.restoreRowHint,
        busy: busy == YourHisaabBusy.checking,
        onTap: idle ? () => bloc.add(const YourHisaabRestoreRequested()) : null,
      ),
      if (undo != null) ...<Widget>[
        _divider(context),
        SettingsRow(
          key: const ValueKey<String>('undo-restore'),
          icon: AppIcons.undoRestore,
          label: strings.restoreRevertRow,
          detail: undo.addedSince > 0
              ? strings.restoreRevertLoses(undo.addedSince)
              : strings.restoreRevertHint(context.backupDay(undo.restoredOn)),
          busy: busy == YourHisaabBusy.undoing,
          onTap: idle ? () => bloc.add(const YourHisaabUndoRequested()) : null,
        ),
      ],
    ];
  }

  static bool _pending(YourHisaabState state) => state is YourHisaabReady && state.pending.isSome();

  static Widget _card(BuildContext context, List<Widget> rows) => Material(
        color: context.colors.surface,
        shape: HisaabShapes.squircle(HisaabRadii.card),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      );

  static Widget _divider(BuildContext context) =>
      Divider(height: 1, thickness: 1, indent: HisaabSpacing.gutter, color: context.colors.hairline);
}
