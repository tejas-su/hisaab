import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';

import '../add_entry/add_entry.dart';
import '../ask_ai/ask_ai.dart';
import '../backup/backup.dart';
import '../core/design/haptics.dart';
import '../core/errors/failure.dart';
import '../core/notifications/bill_reminders.dart';
import '../core/time/clock.dart';
import '../core/time/pay_cycle.dart';
import '../core/usecases/use_case.dart';
import '../core/widgets/hisaab_snackbar_host.dart';
import '../habits/habits.dart';
import '../home/home.dart';
import '../l10n/gen/app_localizations.dart';
import '../ledger/ledger.dart';
import '../onboarding/onboarding.dart';
import '../settings/settings.dart';
import '../spends/spends.dart';
import 'bloc/reminders_bloc.dart';
import 'bloc/reminders_event.dart';
import 'bloc/reminders_state.dart';
import 'main_screen.dart';
import 'widgets/midnight_listener.dart';
import 'widgets/resume_listener.dart';

/// Builds every screen with its Bloc and dependencies: the app's composition root for UI.
abstract final class AppRoutes {
  /// Onboarding; [onFinished] runs once everything is saved, and [onRestored] once a backup from
  /// another phone is brought back instead (FR-ON-1, D139).
  static Widget onboarding(GetIt getIt, {required VoidCallback onFinished, required VoidCallback onRestored}) =>
      MultiBlocProvider(
        providers: <BlocProvider<Object?>>[
          BlocProvider<OnboardingBloc>(
            create: (BuildContext _) => OnboardingBloc(
              drafts: getIt<OnboardingDraftRepository>(),
              completeOnboarding: getIt<CompleteOnboarding>(),
              haptics: getIt<Haptics>(),
            )..add(const OnboardingStarted()),
          ),
          BlocProvider<YourHisaabBloc>(
            create: (BuildContext _) => YourHisaabBloc(
              backups: getIt<BackupRepository>(),
              clock: getIt<Clock>(),
              haptics: getIt<Haptics>(),
              fromOnboarding: true,
            ),
          ),
        ],
        child: HisaabSnackbarHost(
          child: OnboardingPage(onFinished: onFinished, restore: RestoreBackupChip(onRestored: onRestored)),
        ),
      );

  /// Home and Spends; [assemble] plays the blocks entrance once. [onDataReplaced] reloads the app
  /// after a restore, an undo or *Delete everything* in Settings (D139).
  static Widget main(GetIt getIt, {required VoidCallback onDataReplaced, bool assemble = false}) => MultiBlocProvider(
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
              undoBillAmount: getIt<UndoBillAmount>(),
              unskipBill: getIt<UnskipBillOccurrence>(),
              haptics: getIt<Haptics>(),
            )..add(const HomeLoadRequested()),
          ),
          BlocProvider<RemindersBloc>(
            create: (BuildContext _) => RemindersBloc(
              preferences: getIt<AppPreferencesRepository>(),
              arm: getIt<ArmBillReminders>(),
              reminders: getIt<BillReminders>(),
              getCycleSummary: getIt<GetCycleSummary>(),
              ledger: getIt<LedgerRepository>(),
              recurring: getIt<RecurringRepository>(),
            )..add(const RemindersStarted()),
          ),
          BlocProvider<SpendsBloc>(
            create: (BuildContext _) => SpendsBloc(
              getOverview: getIt<GetSpendsOverview>(),
              applyLimits: getIt<ApplySuggestedLimits>(),
              ledger: getIt<LedgerRepository>(),
              haptics: getIt<Haptics>(),
            )..add(const SpendsLoadRequested()),
          ),
          BlocProvider<HabitsBloc>(
            // why: the first load must start with the screen. A lazy provider builds its bloc on the
            // first read; were that the first Add tap, that tray's first frame would have no pill
            // (FR-AD-10 AC-1).
            lazy: false,
            create: (BuildContext _) => HabitsBloc(
              getIndex: getIt<GetHabitIndex>(),
              undoAdd: getIt<UndoUsualAdd>(),
              ledger: getIt<LedgerRepository>(),
            )..add(const HabitsLoadRequested()),
          ),
        ],
        child: Builder(
          // why: a tapped reminder opens Home, then its bill; a resume re-arms them (spec §6).
          builder: (BuildContext context) => BlocListener<RemindersBloc, RemindersState>(
            listener: (BuildContext context, RemindersState state) => _openReminded(context, getIt, state),
            child: ResumeListener(
              onResume: () {
                context.read<RemindersBloc>().add(const RemindersArmRequested());
                context.read<HabitsBloc>().add(const HabitsLoadRequested());
              },
              // why: a habit index is for one day (BR-17); the app may stay open past midnight.
              child: MidnightListener(
                clock: getIt<Clock>(),
                onNewDay: () => context.read<HabitsBloc>().add(const HabitsLoadRequested()),
                child: MainScreen(
                clock: getIt<Clock>(),
                assemble: assemble,
                wrapPrimary: (Widget page) => UsualAddedNotice(child: page),
                onAdd: (EntryKind kind) => openAddTray(context, getIt, kind: kind),
                onEdit: (Entry entry) => openAddTray(context, getIt, editing: Option<Entry>.of(entry)),
                onOpenSettings: () async {
                  final HomeBloc home = context.read<HomeBloc>();
                  final HabitsBloc habits = context.read<HabitsBloc>();
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (BuildContext _) => settings(getIt, onDataReplaced: onDataReplaced)),
                  );
                  // why: category edits (D138) don't pass through the ledger or rules streams Home
                  // listens to, so Home re-reads on the way back; the Add tray takes its tiles from it.
                  home.add(const HomeLoadRequested());
                  // why: neither do a category hidden or a usual forgotten there (FR-SE-2 AC-6).
                  habits.add(const HabitsLoadRequested());
                },
                onOpenBill: (RecurringRule rule) async {
                  final HomeBloc home = context.read<HomeBloc>();
                  // why: a change reloads Home through RecurringRepository.changes; a delete goes
                  // through Home so its Undo shows there.
                  if (await openBillSheet(context, getIt, rule) case BillSheetDeleted(:final RecurringRule rule)) {
                    home.add(HomeBillDeleteRequested(rule));
                  }
                },
                onEnterBill: (Occurrence occurrence) => enterBill(context, getIt, occurrence),
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
            ),
          ),
        ),
      );


  /// Opens the amount sheet of a bill waiting on Home over [context] (D123). The write reloads
  /// Home through the change streams; the outcome goes through Home so its Undo shows there.
  static Future<void> enterBill(BuildContext context, GetIt getIt, Occurrence occurrence) async {
    final HomeBloc home = context.read<HomeBloc>();
    final Option<BillAmountOutcome> outcome = await BillAmountSheet.show(
      context,
      BillAmountBloc(
        occurrence: occurrence,
        getLastAmount: getIt<GetLastBillAmount>(),
        enter: getIt<EnterBillAmount>(),
        skip: getIt<SkipBillOccurrence>(),
        haptics: getIt<Haptics>(),
      )..add(const BillAmountLoadRequested()),
    );
    outcome.map((BillAmountOutcome done) => home.add(HomeBillAmountDone(done)));
  }

  static void _openReminded(BuildContext context, GetIt getIt, RemindersState state) {
    if (state is! RemindersBillOpened) {
      return;
    }
    Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
    state.bill.map((Occurrence occurrence) => enterBill(context, getIt, occurrence));
  }

  /// Asks "Remind you on the day it's due?" once a changing or card bill exists and it was
  /// never answered (spec §5, D126).
  static Future<void> offerReminders(BuildContext context, GetIt getIt) async {
    final bool ask = (await getIt<ShouldAskBillReminders>()(const NoParams()).run()).getOrElse((Failure _) => false);
    if (!ask || !context.mounted) {
      return;
    }
    final Option<bool> answer = await RemindAskSheet.show(context);
    if (answer case Some(:final bool value)) {
      final bool on = (await getIt<AnswerBillReminders>()(value).run()).getOrElse((Failure _) => true);
      // why: a refused permission is otherwise silent, and the ask never comes back (E-i).
      if (value && !on && context.mounted) {
        await RemindAskSheet.showRefused(context);
      }
    }
  }

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

  /// Settings, one level deep (FR-SE); [onDataReplaced] reloads the app after a restore, an undo or
  /// *Delete everything* (D139).
  static Widget settings(GetIt getIt, {required VoidCallback onDataReplaced}) => BlocProvider<IncomeBloc>(
        create: (BuildContext _) => IncomeBloc(
          getIncome: getIt<GetIncome>(),
          recurring: getIt<RecurringRepository>(),
          ledger: getIt<LedgerRepository>(),
        )..add(const IncomeLoadRequested()),
        child: Builder(
          builder: (BuildContext context) => SettingsPage(
            incomeBloc: context.read<IncomeBloc>(),
            onOpenIncome: (Income income) => IncomeSheet.show(
              context,
              IncomeSheetBloc(
                income: income,
                changeAmount: getIt<ChangeIncomeAmount>(),
                correctPay: getIt<CorrectLatestPay>(),
                changeRule: getIt<ChangePayRule>(),
                summary: getIt<GetCycleSummary>(),
                newRuleLabel: AppLocalizations.of(context).categoryName(CategoryKeys.salary),
                haptics: getIt<Haptics>(),
              ),
            ),
            onOpenBills: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => bills(getIt)),
            ),
            onOpenSavings: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => bills(getIt, kind: EntryKind.saved)),
            ),
            themeBloc: context.read<ThemeBloc>(),
            onOpenCategories: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext _) => categories(getIt)),
            ),
            yourHisaab: _yourHisaab(getIt, onDataReplaced: () {
              onDataReplaced();
              context.read<IncomeBloc>().add(const IncomeLoadRequested());
            }),
          ),
        ),
      );

  /// Settings › Categories (FR-SE-2, D138); a *Spent* category's sheet gets its *Your usual* row
  /// with a bloc of its own (AC-6, D153).
  static Widget categories(GetIt getIt) => BlocProvider<CategoriesBloc>(
        create: (BuildContext _) => CategoriesBloc(
          categories: getIt<CategoryRepository>(),
          addOwnCategory: getIt<AddOwnCategory>(),
          renameCategory: getIt<RenameCategory>(),
          changeCategoryIcon: getIt<ChangeCategoryIcon>(),
          setCategoryHidden: getIt<SetCategoryHidden>(),
        )..add(const CategoriesLoadRequested()),
        child: CategoriesPage(
          usualRow: (Category category) => BlocProvider<UsualRowBloc>(
            key: ValueKey<int>(category.id),
            create: (BuildContext _) => UsualRowBloc(
              categoryId: category.id,
              getIndex: getIt<GetHabitIndex>(),
              forget: getIt<ForgetUsual>(),
              restore: getIt<RestoreUsual>(),
              clock: getIt<Clock>(),
            )..add(const UsualRowLoadRequested()),
            child: Builder(
              builder: (BuildContext context) => YourUsualRow(name: category.labelIn(AppLocalizations.of(context))),
            ),
          ),
        ),
      );

  /// Settings' *Your hisaab* group with its bloc (FR-SE-4, D139).
  static Widget _yourHisaab(GetIt getIt, {required VoidCallback onDataReplaced}) => BlocProvider<YourHisaabBloc>(
        create: (BuildContext _) => YourHisaabBloc(
          backups: getIt<BackupRepository>(),
          clock: getIt<Clock>(),
          haptics: getIt<Haptics>(),
        )..add(const YourHisaabLoadRequested()),
        child: YourHisaabNotices(
          onDataReplaced: onDataReplaced,
          child: Builder(
            builder: (BuildContext context) => YourHisaabGroup(
              today: getIt<Clock>().today(),
              onOpenDelete: () {
                final NavigatorState navigator = Navigator.of(context);
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => deleteEverything(
                      getIt,
                      context.read<YourHisaabBloc>(),
                      onDeleted: () {
                        // why: Settings and this page sit on the old data; the root shows
                        // onboarding once it reloads.
                        navigator.popUntil((Route<void> route) => route.isFirst);
                        onDataReplaced();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  /// *Delete everything* (FR-SE-4 AC-4..8), sharing Settings' [yourHisaab] bloc for *Back up first*.
  static Widget deleteEverything(GetIt getIt, YourHisaabBloc yourHisaab, {required VoidCallback onDeleted}) =>
      MultiBlocProvider(
        providers: <BlocProvider<Object?>>[
          BlocProvider<YourHisaabBloc>.value(value: yourHisaab),
          BlocProvider<DeleteEverythingBloc>(
            create: (BuildContext _) => DeleteEverythingBloc(
              deleteEverything: getIt<DeleteEverything>(),
              haptics: getIt<Haptics>(),
            ),
          ),
        ],
        child: DeleteEverythingPage(today: getIt<Clock>().today(), haptics: getIt<Haptics>(), onDeleted: onDeleted),
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
            onAdd: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => billEditor(getIt, kind: kind)));
              if (context.mounted) {
                await offerReminders(context, getIt);
              }
            },
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
  /// caller deletes on [BillSheetDeleted], so its own Undo goes with it. A bill that now changes
  /// may be asked about reminders first.
  static Future<BillSheetOutcome> openBillSheet(BuildContext context, GetIt getIt, RecurringRule rule) async {
    final BillSheetOutcome outcome = await BillSheet.show(
      context,
      BillSheetBloc(rule: rule, editBill: getIt<EditBill>(), getStatus: getIt<GetBillStatus>(), haptics: getIt<Haptics>()),
    );
    // why: a bill switched to *Changes every month* or *Credit card* is the first one that waits.
    if (outcome case BillSheetChanged(:final RecurringRule rule) when rule.amountMode != AmountMode.fixed && context.mounted) {
      await offerReminders(context, getIt);
    }
    return outcome;
  }

  /// Opens the Add tray from Home's [context], reusing Home's summary and categories. Home holds
  /// its numbers until the tray has fully closed, so the drain plays in view (FR-AD-5).
  ///
  /// A new *Spent* tray gets *your usual* from the habits already loaded, so the pill is in its
  /// first frame or not there at all (FR-AD-10 AC-1); a one-tap add is handed back to the
  /// [HabitsBloc] above [context] for its Undo (BR-10).
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
    final HabitsBloc habitsBloc = context.read<HabitsBloc>();
    final HabitsState habits = habitsBloc.state;
    final Option<UsualSpend> usual = habits is HabitsReady && editing.isNone() && kind == EntryKind.spent
        ? UsualSpendDetector.suggest(habits.index, now: getIt<Clock>().now(), categories: categories)
        : const Option<UsualSpend>.none();
    final AddEntryBloc bloc = AddEntryBloc(
      saveEntry: getIt<SaveEntry>(),
      deleteEntry: getIt<DeleteEntry>(),
      addOwnCategory: getIt<AddOwnCategory>(),
      haptics: getIt<Haptics>(),
      clock: getIt<Clock>(),
      categories: categories,
      summary: home is HomeReady ? Option<CycleSummary>.of(home.summary) : const Option<CycleSummary>.none(),
      editing: editing,
      kind: kind,
      usual: usual,
    );
    final HomeBloc homeBloc = context.read<HomeBloc>()..add(const HomeTrayOpened());
    await AddEntryTray.show(context, bloc);
    homeBloc.add(const HomeTrayClosed());
    if (bloc.state case AddEntryFinished(added: Some<Entry>(value: final Entry entry))) {
      usual.map((UsualSpend spend) => habitsBloc.add(HabitsUsualAdded(UsualAdd(entry: entry, category: spend.category))));
    }
  }
}
