import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';

import '../add_entry/add_entry.dart';
import '../ask_ai/ask_ai.dart';
import '../core/design/haptics.dart';
import '../core/errors/failure.dart';
import '../core/time/clock.dart';
import '../core/time/pay_cycle.dart';
import '../home/home.dart';
import '../l10n/gen/app_localizations.dart';
import '../ledger/ledger.dart';
import '../onboarding/onboarding.dart';
import '../settings/settings.dart';
import '../spends/spends.dart';
import 'main_screen.dart';

/// Builds every screen with its Bloc and dependencies: the app's composition root for UI.
abstract final class AppRoutes {
  /// Onboarding; [onFinished] runs once everything is saved.
  static Widget onboarding(GetIt getIt, {required VoidCallback onFinished}) => BlocProvider<OnboardingBloc>(
        create: (BuildContext _) => OnboardingBloc(
          drafts: getIt<OnboardingDraftRepository>(),
          completeOnboarding: getIt<CompleteOnboarding>(),
          haptics: getIt<Haptics>(),
        )..add(const OnboardingStarted()),
        child: OnboardingPage(onFinished: onFinished),
      );

  /// Home and Spends; [assemble] plays the blocks entrance once.
  static Widget main(GetIt getIt, {bool assemble = false}) => MultiBlocProvider(
        providers: <BlocProvider<Object?>>[
          BlocProvider<HomeBloc>(
            create: (BuildContext _) => HomeBloc(
              getCycleSummary: getIt<GetCycleSummary>(),
              postDueRecurring: getIt<PostDueRecurring>(),
              getDueSoonBill: getIt<GetDueSoonBill>(),
              ledger: getIt<LedgerRepository>(),
              recurring: getIt<RecurringRepository>(),
              categories: getIt<CategoryRepository>(),
              deleteEntry: getIt<DeleteEntry>(),
              restoreEntry: getIt<RestoreEntry>(),
              deleteBill: getIt<DeleteBill>(),
              restoreBill: getIt<RestoreBill>(),
              haptics: getIt<Haptics>(),
            )..add(const HomeLoadRequested()),
          ),
          BlocProvider<SpendsBloc>(
            create: (BuildContext _) => SpendsBloc(
              getOverview: getIt<GetSpendsOverview>(),
              applyLimits: getIt<ApplySuggestedLimits>(),
              ledger: getIt<LedgerRepository>(),
              haptics: getIt<Haptics>(),
            )..add(const SpendsLoadRequested()),
          ),
        ],
        child: Builder(
          builder: (BuildContext context) => MainScreen(
            clock: getIt<Clock>(),
            assemble: assemble,
            onAdd: (EntryKind kind) => openAddTray(context, getIt, kind: kind),
            onEdit: (Entry entry) => openAddTray(context, getIt, editing: Option<Entry>.of(entry)),
            onOpenSettings: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => settings(getIt)),
            ),
            onOpenBill: (RecurringRule rule) async {
              final HomeBloc home = context.read<HomeBloc>();
              // why: a change reloads Home through RecurringRepository.changes; a delete goes
              // through Home so its Undo shows there.
              if (await openBillSheet(context, getIt, rule) case BillSheetDeleted(:final RecurringRule rule)) {
                home.add(HomeBillDeleteRequested(rule));
              }
            },
            onAskAi: (PayCycle cycle) => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => askAi(getIt, cycle: cycle)),
            ),
            onSeeEntries: (PayCycle cycle, Option<int> categoryId) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext _) => entries(
                  getIt,
                  cycle: cycle,
                  categoryId: categoryId,
                  onEdit: (Entry entry) => openAddTray(context, getIt, editing: Option<Entry>.of(entry)),
                ),
              ),
            ),
          ),
        ),
      );

  /// Every entry of [cycle], filtered to [categoryId] when set (FR-SP-6).
  static Widget entries(
    GetIt getIt, {
    required PayCycle cycle,
    required Option<int> categoryId,
    required ValueChanged<Entry> onEdit,
  }) =>
      BlocProvider<EntriesBloc>(
        create: (BuildContext _) => EntriesBloc(
          cycle: cycle,
          filter: categoryId,
          ledger: getIt<LedgerRepository>(),
          categories: getIt<CategoryRepository>(),
          deleteEntry: getIt<DeleteEntry>(),
          restoreEntry: getIt<RestoreEntry>(),
          haptics: getIt<Haptics>(),
        )..add(const EntriesLoadRequested()),
        child: EntriesPage(cycle: cycle, today: getIt<Clock>().today(), onEdit: onEdit),
      );

  /// Ask AI for [cycle], the one Spends shows (FR-AI).
  static Widget askAi(GetIt getIt, {required PayCycle cycle}) => Builder(
        // why: the category names are read here, not in `create`, which may not listen to
        // inherited widgets such as the localisations.
        builder: (BuildContext context) {
          final AppLocalizations strings = AppLocalizations.of(context);
          return BlocProvider<AskAiBloc>(
            create: (BuildContext _) => AskAiBloc(
              cycle: cycle,
              getInput: getIt<GetPromptInput>(),
              handoff: getIt<AiHandoff>(),
              haptics: getIt<Haptics>(),
              nameOf: (Category category) => category.labelIn(strings),
            )..add(const AskAiLoadRequested()),
            child: const AskAiPage(),
          );
        },
      );

  /// Settings, one level deep (FR-SE).
  static Widget settings(GetIt getIt) => Builder(
        builder: (BuildContext context) => SettingsPage(
          onOpenBills: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (BuildContext _) => bills(getIt)),
          ),
          onOpenSavings: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (BuildContext _) => bills(getIt, kind: EntryKind.saved)),
          ),
        ),
      );

  /// The Fixed bills list, or Savings for [kind] *Saved* (FR-SE-1, D120): Add opens the editor,
  /// a row opens the sheet.
  static Widget bills(GetIt getIt, {EntryKind kind = EntryKind.spent}) => BlocProvider<BillsBloc>(
        create: (BuildContext _) => BillsBloc(
          getBills: getIt<GetBills>(),
          deleteBill: getIt<DeleteBill>(),
          restoreBill: getIt<RestoreBill>(),
          recurring: getIt<RecurringRepository>(),
          haptics: getIt<Haptics>(),
          getSavedTotal: getIt<GetSavedTotal>(),
          ledger: getIt<LedgerRepository>(),
          kind: kind,
        )..add(const BillsLoadRequested()),
        child: Builder(
          builder: (BuildContext context) => BillsPage(
            kind: kind,
            onPutInExtra: kind == EntryKind.saved
                ? () => PutInSheet.show(
                      context,
                      PutInExtraBloc(
                        getCycleSummary: getIt<GetCycleSummary>(),
                        putInExtra: getIt<PutInExtra>(),
                        haptics: getIt<Haptics>(),
                      )..add(const PutInExtraLoadRequested()),
                    )
                : null,
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => billEditor(getIt, kind: kind)),
            ),
            onEdit: (RecurringRule bill) async {
              final BillsBloc bills = context.read<BillsBloc>();
              // why: a change reloads the list through RecurringRepository.changes; only a
              // delete needs the list, which owns its Undo.
              if (await openBillSheet(context, getIt, bill) case BillSheetDeleted(:final RecurringRule rule)) {
                bills.add(BillsDeleteRequested(rule));
              }
            },
          ),
        ),
      );

  /// Adds a bill, or a saving for [kind] *Saved*, one question at a time (FR-SE-1, D120).
  static Widget billEditor(GetIt getIt, {EntryKind kind = EntryKind.spent}) => BlocProvider<BillEditorBloc>(
        create: (BuildContext _) => BillEditorBloc(addBill: getIt<AddBill>(), haptics: getIt<Haptics>(), kind: kind),
        child: const BillEditorPage(),
      );

  /// Opens [rule]'s bill sheet over [context] (FR-SE-1, D118) and reports what it did; the
  /// caller deletes on [BillSheetDeleted], so its own Undo goes with it.
  static Future<BillSheetOutcome> openBillSheet(BuildContext context, GetIt getIt, RecurringRule rule) => BillSheet.show(
        context,
        BillSheetBloc(rule: rule, editBill: getIt<EditBill>(), getStatus: getIt<GetBillStatus>(), haptics: getIt<Haptics>()),
      );

  /// Opens the Add tray from Home's [context], reusing Home's summary and categories. Home holds
  /// its numbers until the tray has fully closed, so the drain plays in view (FR-AD-5).
  static Future<void> openAddTray(
    BuildContext context,
    GetIt getIt, {
    EntryKind kind = EntryKind.spent,
    Option<Entry> editing = const Option<Entry>.none(),
  }) async {
    final HomeState home = context.read<HomeBloc>().state;
    final List<Category> categories = home is HomeReady
        ? home.categories.values.toList()
        : (await getIt<CategoryRepository>().all().run()).getOrElse((Failure _) => const <Category>[]);
    if (!context.mounted) {
      return;
    }
    final AddEntryBloc bloc = AddEntryBloc(
      saveEntry: getIt<SaveEntry>(),
      deleteEntry: getIt<DeleteEntry>(),
      haptics: getIt<Haptics>(),
      clock: getIt<Clock>(),
      categories: categories,
      summary: home is HomeReady ? Option<CycleSummary>.of(home.summary) : const Option<CycleSummary>.none(),
      editing: editing,
      kind: kind,
    );
    final HomeBloc homeBloc = context.read<HomeBloc>()..add(const HomeTrayOpened());
    await AddEntryTray.show(context, bloc);
    homeBloc.add(const HomeTrayClosed());
  }
}
