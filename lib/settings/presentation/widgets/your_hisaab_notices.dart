import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../backup/backup.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Shows each new notice of a [YourHisaabBloc] on the nearest [HisaabSnackbarHost], with *Undo*
/// after a restore, and calls [onDataReplaced] when the data under the app changed.
class YourHisaabNotices extends StatelessWidget {
  const YourHisaabNotices({super.key, required this.onDataReplaced, required this.child});

  final VoidCallback onDataReplaced;
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<YourHisaabBloc, YourHisaabState>(
        listenWhen: (YourHisaabState previous, YourHisaabState current) => _count(current) > _count(previous),
        listener: _show,
        child: child,
      );

  void _show(BuildContext context, YourHisaabState state) {
    if (state is! YourHisaabReady) {
      return;
    }
    state.notice.map((YourHisaabNotice notice) {
      if (notice.replacedData) {
        onDataReplaced();
      }
      HisaabSnackbarHost.of(context).show(
        HisaabSnackbar(
          message: context.noticeText(notice),
          action: notice is RestoredNotice
              ? HisaabSnackbarAction(
                  label: AppLocalizations.of(context).undo,
                  onPressed: () => context.read<YourHisaabBloc>().add(const YourHisaabUndoRequested()),
                )
              : null,
        ),
      );
    });
  }

  static int _count(YourHisaabState state) => switch (state) {
        YourHisaabReady(:final int noticeCount) => noticeCount,
        YourHisaabLoading() => 0,
      };
}
