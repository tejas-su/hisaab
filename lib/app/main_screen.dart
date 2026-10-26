import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/time/clock.dart';
import '../home/home.dart';
import '../ledger/ledger.dart';
import '../spends/spends.dart';
import 'app_shell.dart';
import 'widgets/midnight_listener.dart';
import 'widgets/resume_listener.dart';

/// Home and Spends in the adaptive shell, with Home reloading on resume and at midnight
/// (SPEC BR-8).
///
/// Needs a [HomeCubit] above it. [clock] times midnight; the callbacks open the Add tray and
/// Settings.
class MainScreen extends StatelessWidget {
  const MainScreen({
    super.key,
    required this.clock,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenSettings,
    this.assemble = false,
  });

  final Clock clock;
  final ValueChanged<EntryKind> onAdd;
  final ValueChanged<Entry> onEdit;
  final VoidCallback onOpenSettings;
  final bool assemble;

  @override
  Widget build(BuildContext context) {
    final HomeCubit home = context.read<HomeCubit>();
    return Scaffold(
      body: MidnightListener(
        clock: clock,
        onNewDay: home.load,
        child: ResumeListener(
          onResume: home.load,
          child: AppShell(
            home: HomePage(onAdd: onAdd, onEdit: onEdit, onOpenSettings: onOpenSettings, assemble: assemble),
            spends: const SpendsPage(),
            onAdd: () => onAdd(EntryKind.spent),
          ),
        ),
      ),
    );
  }
}
