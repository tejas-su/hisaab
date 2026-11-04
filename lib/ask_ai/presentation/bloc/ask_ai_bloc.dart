import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../ledger/ledger.dart';
import '../../domain/ai_handoff.dart';
import '../../domain/ask_goal.dart';
import '../../domain/chat_gpt_link.dart';
import '../../domain/entities/prompt_choice.dart';
import '../../domain/entities/prompt_input.dart';
import '../../domain/prompt_builder.dart';
import '../../domain/usecase/get_prompt_input.dart';
import 'ask_ai_event.dart';
import 'ask_ai_state.dart';

/// Owns the Ask AI choices and the prompt they build for one cycle (SPEC BR-15, FR-AI).
///
/// Driven by the page: [AskAiLoadRequested] when it opens, a choice event per control, and an
/// [AskAiHandoffEvent] per action button. Every choice rebuilds the prompt without reloading.
class AskAiBloc extends Bloc<AskAiEvent, AskAiState> {
  /// The cycle is the one Spends was showing; the name function gives each category's shown name.
  AskAiBloc({required this._cycle, required this._getInput, required this._handoff, required this._haptics, required this._nameOf})
    : super(const AskAiLoading()) {
    on<AskAiLoadRequested>(_onLoadRequested, transformer: restartable());
    on<AskAiGoalChosen>(
      (AskAiGoalChosen event, Emitter<AskAiState> emit) => _choose(emit, (PromptChoice c) => c.copyWith(goal: event.goal)),
    );
    on<AskAiPeriodChosen>(
      (AskAiPeriodChosen event, Emitter<AskAiState> emit) => _choose(emit, (PromptChoice c) => c.copyWith(period: event.period)),
    );
    on<AskAiNotesHidden>(
      (AskAiNotesHidden event, Emitter<AskAiState> emit) => _choose(emit, (PromptChoice c) => c.copyWith(hideNotes: event.hide)),
    );
    on<AskAiQuestionChanged>(_onQuestionChanged);
    // why: a second tap while the clipboard or the share sheet is still busy would copy, open or
    // share twice.
    on<AskAiHandoffEvent>(_onHandoff, transformer: droppable());
  }

  final PayCycle _cycle;
  final GetPromptInput _getInput;
  final AiHandoff _handoff;
  final Haptics _haptics;
  final String Function(Category) _nameOf;

  Future<void> _onLoadRequested(AskAiLoadRequested event, Emitter<AskAiState> emit) async {
    final AskAiState current = state;
    final PromptChoice choice = current is AskAiReady ? current.choice : const PromptChoice();
    (await _getInput(_cycle).run()).match((Failure _) => emit(const AskAiFailed()), (PromptInput input) => emit(_ready(input, choice)));
  }

  /// Applies a tapped control's [change] and rebuilds the prompt, with a tick.
  void _choose(Emitter<AskAiState> emit, PromptChoice Function(PromptChoice) change) {
    final AskAiState current = state;
    if (current is! AskAiReady) {
      return;
    }
    unawaited(_haptics.tick());
    emit(_ready(current.input, change(current.choice), toasts: current.toasts));
  }

  void _onQuestionChanged(AskAiQuestionChanged event, Emitter<AskAiState> emit) {
    final AskAiState current = state;
    if (current is! AskAiReady) {
      return;
    }
    final String question = event.question.length > PromptChoice.maxQuestionLength
        ? event.question.substring(0, PromptChoice.maxQuestionLength)
        : event.question;
    // why: the own-question field is always visible (FR-AI-1), so typing in it is the pick; an
    // emptied field keeps the pick, which leaves the actions disabled until there is a question.
    final AskGoal goal = question.trim().isEmpty ? current.choice.goal : AskGoal.ownQuestion;
    emit(
      _ready(
        current.input,
        current.choice.copyWith(goal: goal, question: question),
        toasts: current.toasts,
      ),
    );
  }

  Future<void> _onHandoff(AskAiHandoffEvent event, Emitter<AskAiState> emit) async {
    final AskAiState current = state;
    if (current is! AskAiReady || !current.choice.canSend) {
      return;
    }
    final String text = current.prompt.text;
    final bool toast = switch (event) {
      AskAiChatGptPressed() => await _copyAndOpen(text),
      AskAiOtherAiPressed() => await _handoff.share(text).then((_) => false),
      AskAiCopyPressed() => await _handoff.copy(text).then((_) => true),
    };
    unawaited(_haptics.success());
    if (toast && state == current) {
      emit(AskAiReady(input: current.input, choice: current.choice, prompt: current.prompt, toasts: current.toasts + 1));
    }
  }

  /// Copies [text] and opens ChatGPT with it; true when nothing opened, so a toast must say to
  /// paste. A prompt too long to prefill needs no toast: the screen said so before the tap.
  Future<bool> _copyAndOpen(String text) async {
    await _handoff.copy(text);
    return !await _handoff.open(ChatGptLink.prefilled(text).getOrElse(() => ChatGptLink.home));
  }

  AskAiReady _ready(PromptInput input, PromptChoice choice, {int toasts = 0}) {
    final PromptChoice offered = _offered(input, choice);
    return AskAiReady(
      input: input,
      choice: offered,
      prompt: PromptBuilder.build(input, offered, nameOf: _nameOf),
      toasts: toasts,
    );
  }

  // why: the on-track goal is hidden for a past cycle, which has no today to forecast from
  // (FR-AI-1); a pick of it, or one left over from before a reload, falls back to the default.
  static PromptChoice _offered(PromptInput input, PromptChoice choice) =>
      choice.goal == AskGoal.onTrack && !input.offersOnTrack ? choice.copyWith(goal: const PromptChoice().goal) : choice;
}
