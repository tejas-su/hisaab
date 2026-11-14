import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../domain/entities/month_story.dart';
import '../../domain/usecase/get_month_story.dart';
import 'month_story_event.dart';
import 'month_story_state.dart';

/// Owns the month story of the cycle [cyclesBack] cycles before the current one (SPEC FR-SP-7).
/// Driven by [MonthStoryLoadRequested] from the route when it opens, and from Try again.
class MonthStoryBloc extends Bloc<MonthStoryEvent, MonthStoryState> {
  MonthStoryBloc({required this._getStory, required this.cyclesBack}) : super(const MonthStoryLoading()) {
    // why: a Try again during a slow load must not let the older answer land last.
    on<MonthStoryLoadRequested>(_onLoadRequested, transformer: restartable());
  }

  final GetMonthStory _getStory;

  /// Which cycle: 1 is the one before the current cycle.
  final int cyclesBack;

  Future<void> _onLoadRequested(MonthStoryLoadRequested event, Emitter<MonthStoryState> emit) async {
    final Either<Failure, Option<MonthStory>> loaded = await _getStory(cyclesBack).run();
    emit(loaded.match(
      (Failure failure) {
        AppLogger.log(tag: 'month_story.load_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        return MonthStoryFailed(failure);
      },
      (Option<MonthStory> story) => story.match(() => const MonthStoryGone(), MonthStoryReady.new),
    ));
  }
}
