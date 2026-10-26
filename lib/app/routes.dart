import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';

import '../add_entry/add_entry.dart';
import '../core/design/haptics.dart';
import '../core/errors/failure.dart';
import '../core/time/clock.dart';
import '../home/home.dart';
import '../ledger/ledger.dart';
import '../onboarding/onboarding.dart';
import '../settings/settings.dart';
import 'main_screen.dart';

/// Builds every screen with its Cubit and dependencies: the app's composition root for UI.
abstract final class AppRoutes {
  /// Onboarding; [onFinished] runs once everything is saved.
  static Widget onboarding(GetIt getIt, {required VoidCallback onFinished}) => BlocProvider<OnboardingCubit>(
        create: (BuildContext _) => OnboardingCubit(
          drafts: getIt<OnboardingDraftRepository>(),
          completeOnboarding: getIt<CompleteOnboarding>(),
          haptics: getIt<Haptics>(),
        )..start(),
        child: OnboardingPage(onFinished: onFinished),
      );

  /// Home and Spends; [assemble] plays the blocks entrance once.
  static Widget main(GetIt getIt, {bool assemble = false}) => BlocProvider<HomeCubit>(
        create: (BuildContext _) => HomeCubit(
          getCycleSummary: getIt<GetCycleSummary>(),
          postDueRecurring: getIt<PostDueRecurring>(),
          getDueSoonBill: getIt<GetDueSoonBill>(),
          ledger: getIt<LedgerRepository>(),
          recurring: getIt<RecurringRepository>(),
          categories: getIt<CategoryRepository>(),
          deleteEntry: getIt<DeleteEntry>(),
          restoreEntry: getIt<RestoreEntry>(),
          haptics: getIt<Haptics>(),
        )..load(),
        child: Builder(
          builder: (BuildContext context) => MainScreen(
            clock: getIt<Clock>(),
            assemble: assemble,
            onAdd: (EntryKind kind) => openAddTray(context, getIt, kind: kind),
            onEdit: (Entry entry) => openAddTray(context, getIt, editing: Option<Entry>.of(entry)),
            onOpenSettings: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => settings(getIt)),
            ),
          ),
        ),
      );

  /// Settings, one level deep (FR-SE).
  static Widget settings(GetIt getIt) => Builder(
        builder: (BuildContext context) => SettingsPage(
          onOpenBills: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (BuildContext _) => bills(getIt)),
          ),
        ),
      );

  /// The Fixed bills list (FR-SE-1); add and edit open the bill editor.
  static Widget bills(GetIt getIt) => BlocProvider<BillsCubit>(
        create: (BuildContext _) => BillsCubit(
          getBills: getIt<GetBills>(),
          deleteBill: getIt<DeleteBill>(),
          restoreBill: getIt<RestoreBill>(),
          recurring: getIt<RecurringRepository>(),
          haptics: getIt<Haptics>(),
        )..load(),
        child: Builder(
          builder: (BuildContext context) => BillsPage(
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => billEditor(getIt)),
            ),
            onEdit: (RecurringRule bill) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext editor) => billEditor(
                  getIt,
                  editing: Option<RecurringRule>.of(bill),
                  onDelete: () {
                    Navigator.of(editor).pop();
                    context.read<BillsCubit>().delete(bill);
                  },
                ),
              ),
            ),
          ),
        ),
      );

  /// Adds a bill, or changes [editing]; [onDelete] offers Delete when changing one.
  static Widget billEditor(
    GetIt getIt, {
    Option<RecurringRule> editing = const Option<RecurringRule>.none(),
    VoidCallback? onDelete,
  }) =>
      BlocProvider<BillEditorCubit>(
        create: (BuildContext _) => BillEditorCubit(
          addBill: getIt<AddBill>(),
          editBill: getIt<EditBill>(),
          haptics: getIt<Haptics>(),
          editing: editing,
        ),
        child: BillEditorPage(onDelete: onDelete),
      );

  /// Opens the Add tray from Home's [context], reusing Home's summary and categories.
  static Future<void> openAddTray(
    BuildContext context,
    GetIt getIt, {
    EntryKind kind = EntryKind.spent,
    Option<Entry> editing = const Option<Entry>.none(),
  }) async {
    final HomeState home = context.read<HomeCubit>().state;
    final List<Category> categories = home is HomeReady
        ? home.categories.values.toList()
        : (await getIt<CategoryRepository>().all().run()).getOrElse((Failure _) => const <Category>[]);
    if (!context.mounted) {
      return;
    }
    final AddEntryCubit cubit = AddEntryCubit(
      saveEntry: getIt<SaveEntry>(),
      deleteEntry: getIt<DeleteEntry>(),
      haptics: getIt<Haptics>(),
      clock: getIt<Clock>(),
      categories: categories,
      summary: home is HomeReady ? Option<CycleSummary>.of(home.summary) : const Option<CycleSummary>.none(),
      editing: editing,
      kind: kind,
    );
    return AddEntryTray.show(context, cubit);
  }
}
