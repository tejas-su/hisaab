import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/haptics.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/delete_everything_bloc.dart';
import '../bloc/delete_everything_event.dart';
import '../bloc/delete_everything_state.dart';
import '../bloc/your_hisaab_bloc.dart';
import '../bloc/your_hisaab_event.dart';
import '../bloc/your_hisaab_state.dart';
import '../widgets/backup_copy.dart';
import '../widgets/delete_everything_list.dart';
import '../widgets/dialog_key.dart';
import '../widgets/hold_to_delete_key.dart';

/// *Delete everything*: what goes, *Back up first*, and the hold key (SPEC FR-SE-4 AC-4..8,
/// UI_DESIGN §5.6). A full page rather than a dialog, so the restore dialog stays the only one.
///
/// Needs a [YourHisaabBloc] (for *Back up first* and the last-backup line) and a
/// [DeleteEverythingBloc] above it. [onDeleted] runs once everything is gone.
class DeleteEverythingPage extends StatelessWidget {
  const DeleteEverythingPage({super.key, required this.today, required this.haptics, required this.onDeleted});

  final CalendarDate today;
  final Haptics haptics;
  final VoidCallback onDeleted;

  /// The page's widest content, so lines stay readable on a tablet.
  static const double maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return BlocBuilder<DeleteEverythingBloc, DeleteEverythingState>(
      builder: (BuildContext context, DeleteEverythingState state) => PopScope(
        canPop: state is DeleteEverythingIdle,
        child: Scaffold(
          appBar: AppBar(
            leadingWidth: HisaabBackButton.leadingWidth,
            leading: const Padding(padding: HisaabBackButton.leadingPadding, child: HisaabBackButton()),
            titleSpacing: HisaabSpacing.s,
            title: Text(strings.deleteAllTitle),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            top: false,
            child: HisaabSnackbarHost(
              child: Builder(builder: (BuildContext context) => _listeners(context, _body(context, strings, state))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _listeners(BuildContext context, Widget child) => MultiBlocListener(
        listeners: <BlocListener<Object?, Object?>>[
          BlocListener<YourHisaabBloc, YourHisaabState>(
            listenWhen: (YourHisaabState previous, YourHisaabState current) => _noticeCount(current) > _noticeCount(previous),
            listener: _showNotice,
          ),
          BlocListener<DeleteEverythingBloc, DeleteEverythingState>(
            listener: _onDeleteState,
          ),
        ],
        child: child,
      );

  void _showNotice(BuildContext context, YourHisaabState state) {
    if (state case YourHisaabReady(:final notice)) {
      notice.map(
        (YourHisaabNotice shown) => HisaabSnackbarHost.of(context).show(HisaabSnackbar(message: context.noticeText(shown))),
      );
    }
  }

  void _onDeleteState(BuildContext context, DeleteEverythingState state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    switch (state) {
      case DeleteEverythingDone():
        SemanticsService.sendAnnouncement(View.of(context), strings.deleteAllDoneSpoken, Directionality.of(context));
        onDeleted();
      case DeleteEverythingIdle(failures: > 0):
        HisaabSnackbarHost.of(context).show(HisaabSnackbar(message: strings.deleteAllFailed));
      case DeleteEverythingIdle() || DeleteEverythingWorking():
        break;
    }
  }

  Widget _body(BuildContext context, AppLocalizations strings, DeleteEverythingState state) {
    final TextTheme text = Theme.of(context).textTheme;
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, HisaabSpacing.xxl),
          children: <Widget>[
            Text(strings.deleteAllLead, style: text.bodyLarge),
            const SizedBox(height: HisaabSpacing.l),
            const DeleteEverythingList(),
            const SizedBox(height: HisaabSpacing.l),
            _stays(context, strings.deleteAllStays),
            const SizedBox(height: HisaabSpacing.s),
            _stays(context, strings.deleteAllPhoneSafe),
            const SizedBox(height: HisaabSpacing.xl),
            _backUpFirst(context, strings, deleting: state is DeleteEverythingWorking),
            const SizedBox(height: HisaabSpacing.xl),
            HoldToDeleteKey(
              haptics: haptics,
              busy: state is DeleteEverythingWorking,
              onConfirmed: () => context.read<DeleteEverythingBloc>().add(const DeleteEverythingConfirmed()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stays(BuildContext context, String line) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(child: AppIcon(AppIcons.check, color: context.colors.ink2, size: 20)),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(child: Text(line, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2))),
        ],
      );

  Widget _backUpFirst(BuildContext context, AppLocalizations strings, {required bool deleting}) =>
      BlocBuilder<YourHisaabBloc, YourHisaabState>(
        builder: (BuildContext context, YourHisaabState state) {
          final YourHisaabReady? ready = state is YourHisaabReady ? state : null;
          final bool busy = ready?.busy == YourHisaabBusy.backingUp;
          final String line = switch (ready?.status.lastBackedUp) {
            null => '',
            final last when last.isNone() => strings.deleteAllNoBackup,
            final last => context.lastBackup(last, today),
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: HisaabSpacing.s),
              DialogKey(
                key: const ValueKey<String>('back-up-first'),
                label: busy ? strings.backUpBusy : strings.deleteAllBackUpFirst,
                leading: AppIcon(busy ? AppIcons.busy : AppIcons.backUp),
                onPressed: busy || deleting ? null : () => context.read<YourHisaabBloc>().add(const YourHisaabBackUpRequested()),
              ),
            ],
          );
        },
      );

  static int _noticeCount(YourHisaabState state) => switch (state) {
        YourHisaabReady(:final int noticeCount) => noticeCount,
        YourHisaabLoading() => 0,
      };
}
