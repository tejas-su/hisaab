import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../core/time/clock.dart';
import '../../../ledger/ledger.dart';
import '../../domain/afford_done_by.dart';
import '../../domain/affordability.dart';
import '../../domain/entities/afford_answer.dart';
import '../../domain/entities/afford_context.dart';
import '../../domain/entities/saving_started.dart';
import '../../domain/usecase/get_afford_inputs.dart';
import '../../domain/usecase/start_saving_for.dart';
import 'afford_event.dart';
import 'afford_state.dart';

/// Owns the *Can I afford it?* sheet (SPEC BR-24, FR-SP-9): the typed draft, the step, the answer
/// and *Start saving*. Driven only by the sheet's events; it stores nothing until *Start saving*.
class AffordBloc extends Bloc<AffordEvent, AffordState> {
  AffordBloc({
    required this._getInputs,
    required this._startSaving,
    required this._clock,
    required this._haptics,
  }) : super(const AffordItemStep()) {
    on<AffordNameChanged>(_onNameChanged);
    on<AffordKeyPressed>((AffordKeyPressed event, Emitter<AffordState> emit) => _edit(emit, (int r) => AmountInput.append(r, event.key)));
    on<AffordBackspacePressed>((AffordBackspacePressed _, Emitter<AffordState> emit) => _edit(emit, (int r) => Option<int>.of(AmountInput.backspace(r))));
    on<AffordCleared>((AffordCleared _, Emitter<AffordState> emit) => _edit(emit, (int _) => const Option<int>.of(0)));
    // why: a second tap on Next while the saving lookup is in flight is dropped.
    on<AffordNextPressed>(_onNextPressed, transformer: droppable());
    on<AffordHaveChosen>(_onHaveChosen);
    // why: the newest request wins, so an older, slower read never lands a stale answer last.
    on<AffordAnswerRequested>(_onAnswerRequested, transformer: restartable());
    on<AffordWaysToggled>(_onWaysToggled);
    // why: a second tap while the saving is written is dropped, so it is never made twice.
    on<AffordStartSavingPressed>(_onStartSavingPressed, transformer: droppable());
    on<AffordBackPressed>(_onBackPressed);
  }

  final GetAffordInputs _getInputs;
  final StartSavingFor _startSaving;
  final Clock _clock;
  final Haptics _haptics;

  void _onNameChanged(AffordNameChanged event, Emitter<AffordState> emit) {
    if (state case AffordItemStep(:final AffordDraft draft)) {
      emit(AffordItemStep(draft.copyWith(name: event.name)));
    }
  }

  // why: step 1 edits the price; step 2 edits the saved amount, and only after *Yes*.
  void _edit(Emitter<AffordState> emit, Option<int> Function(int rupees) edit) {
    final AffordState current = state;
    final AffordDraft draft = current.draft;
    final AffordState? next = switch (current) {
      AffordItemStep() =>
        edit(draft.price).match(() => _refused(current), (int price) => AffordItemStep(draft.copyWith(price: price))),
      AffordHaveStep() when draft.saidYes =>
        edit(draft.have.floorMajor)
            .match(() => _refused(current), (int have) => AffordHaveStep(draft.copyWith(have: Money.fromMajor(have)))),
      _ => null,
    };
    if (next != null) {
      emit(next);
    }
  }

  AffordState _refused(AffordState current) {
    unawaited(_haptics.reject());
    final AffordDraft draft = current.draft.copyWith(rejections: current.draft.rejections + 1);
    return current is AffordItemStep ? AffordItemStep(draft) : AffordHaveStep(draft);
  }

  // why: a saving with the item's name prefills step 2 with what it holds (D221).
  Future<void> _onNextPressed(AffordNextPressed event, Emitter<AffordState> emit) async {
    final AffordState current = state;
    if (current is! AffordItemStep || !current.draft.canGoOn) {
      return;
    }
    final Either<Failure, AffordContext> read = await _getInputs(current.draft.name).run();
    final AffordDraft draft = read.match(
      (Failure failure) {
        _log('afford.lookup_failed', failure);
        return current.draft;
      },
      (AffordContext context) => context.existingSaving.isSome()
          ? current.draft.copyWith(saidYes: true, have: context.existingSetAside)
          : current.draft,
    );
    emit(AffordHaveStep(draft));
  }

  void _onHaveChosen(AffordHaveChosen event, Emitter<AffordState> emit) {
    if (state case AffordHaveStep(:final AffordDraft draft)) {
      emit(AffordHaveStep(draft.copyWith(saidYes: event.saved)));
    }
  }

  Future<void> _onAnswerRequested(AffordAnswerRequested event, Emitter<AffordState> emit) async {
    final AffordDraft draft = state.draft;
    if (state is! AffordHaveStep && state is! AffordLoading) {
      return;
    }
    emit(AffordLoading(draft));
    final Either<Failure, AffordContext> read = await _getInputs(draft.name).run();
    // why: Back while it loaded left the answer; it must not land over step 2.
    if (state is! AffordLoading) {
      return;
    }
    emit(read.match((Failure failure) {
      _log('afford.answer_failed', failure);
      return AffordFailed(draft);
    }, (AffordContext context) => _answered(draft, context)));
  }

  AffordAnswered _answered(AffordDraft draft, AffordContext context) {
    final AffordAnswer answer = Affordability.answer(
      AffordInputs(price: draft.priceMoney, have: draft.haveMoney, room: context.room, days: context.days, usual: context.usual),
    );
    return AffordAnswered(
      draft,
      answer: answer,
      usual: context.usual,
      doneBy: AffordDoneBy.of(answer, context, _clock.today()),
      existing: context.existingSaving,
    );
  }

  void _onWaysToggled(AffordWaysToggled event, Emitter<AffordState> emit) {
    if (state case final AffordAnswered answered) {
      emit(answered.copyWith(waysOpen: !answered.waysOpen));
    }
  }

  // why: the saving is looked up again on every try, so a retry after a half-made saving
  // completes that one instead of making a second; the Undo still follows the answer's saving.
  Future<void> _onStartSavingPressed(AffordStartSavingPressed event, Emitter<AffordState> emit) async {
    final AffordState current = state;
    if (current is! AffordAnswered || current.answer.verdict != AffordVerdict.saveUp) {
      return;
    }
    emit(current.copyWith(saving: true, saveFailed: false));
    final Either<Failure, RecurringRule> saved = await _getInputs(current.draft.name)
        .flatMap((AffordContext context) => _startSaving(_paramsFor(current, context)))
        .run();
    saved.match(
      (Failure failure) {
        _log('afford.save_failed', failure);
        unawaited(_haptics.reject());
        emit(current.copyWith(saving: false, saveFailed: true));
      },
      (RecurringRule rule) {
        unawaited(_haptics.success());
        emit(AffordSavingStarted(current.draft, SavingStarted(rule: rule, previous: current.existing)));
      },
    );
  }

  // why: a re-checked saving keeps what it holds (S), so its target is price − H + S: the money
  // still needed on top of S. A new saving has S = 0, so its target is the need (D220, D222).
  static StartSavingParams _paramsFor(AffordAnswered answered, AffordContext context) => StartSavingParams(
        name: answered.draft.name.trim(),
        monthly: answered.answer.spare,
        target: _withinCap(answered.answer.need + context.existingSetAside),
        nextCycle: context.nextCycle,
        existing: context.existingSaving,
      );

  // why: S on top of a price at the 9-digit cap would pass it; a target is never more than can be
  // typed (BR-23).
  static Money _withinCap(Money target) => target > _targetCap ? _targetCap : target;

  static final Money _targetCap = Money.fromMajor(AmountInput.maxRupees);

  void _onBackPressed(AffordBackPressed event, Emitter<AffordState> emit) {
    final AffordDraft draft = state.draft;
    emit(switch (state) {
      AffordItemStep() || AffordClosed() => AffordClosed(draft),
      AffordHaveStep() => AffordItemStep(draft),
      AffordLoading() || AffordAnswered() || AffordFailed() || AffordSavingStarted() => AffordHaveStep(draft),
    });
  }

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
}
