import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/your_hisaab_bloc.dart';
import '../bloc/your_hisaab_event.dart';
import '../bloc/your_hisaab_state.dart';
import 'backup_copy.dart';

/// Onboarding's *Restore a backup* chip, for someone moving from another phone (SPEC FR-ON-1).
///
/// Needs a [YourHisaabBloc] built `fromOnboarding` above it and a [HisaabSnackbarHost]. A good
/// file restores at once and calls [onRestored]; a bad one shows why on the snackbar.
class RestoreBackupChip extends StatelessWidget {
  const RestoreBackupChip({super.key, required this.onRestored});

  final VoidCallback onRestored;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return BlocConsumer<YourHisaabBloc, YourHisaabState>(
      listenWhen: (YourHisaabState previous, YourHisaabState current) => _noticeCount(current) > _noticeCount(previous),
      listener: _onNotice,
      builder: (BuildContext context, YourHisaabState state) => HisaabChip(
        key: const ValueKey<String>('restore-a-backup'),
        label: strings.restoreLink,
        semanticLabel: strings.restoreLinkSpoken,
        icon: AppIcons.restore,
        onPressed: _idle(state) ? () => context.read<YourHisaabBloc>().add(const YourHisaabRestoreRequested()) : null,
      ),
    );
  }

  void _onNotice(BuildContext context, YourHisaabState state) {
    if (state is! YourHisaabReady) {
      return;
    }
    state.notice.map((YourHisaabNotice notice) {
      if (notice.replacedData) {
        onRestored();
        return;
      }
      HisaabSnackbarHost.of(context).show(HisaabSnackbar(message: context.noticeText(notice)));
    });
  }

  static int _noticeCount(YourHisaabState state) => switch (state) {
        YourHisaabReady(:final int noticeCount) => noticeCount,
        YourHisaabLoading() => 0,
      };

  static bool _idle(YourHisaabState state) => switch (state) {
        YourHisaabReady(:final YourHisaabBusy busy) => busy == YourHisaabBusy.none,
        YourHisaabLoading() => true,
      };
}
