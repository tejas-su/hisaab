import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../domain/entities/nudge_state.dart';
import '../model/nudge_state_model.dart';

/// Converts between [NudgeStateModel] rows and [NudgeState] entities.
abstract final class NudgeStateMapper {
  /// Returns [Right] with the state, or [Left] with `InvalidDataFailure` for a bad armed time or day.
  static Either<Failure, NudgeState> toEntity(NudgeStateModel model) => _instant(model.armedFor).flatMap(
        (Option<DateTime> armedFor) => _day(model.restUntil).map(
          (Option<CalendarDate> restUntil) => NudgeState(
            categoryId: model.categoryId,
            armedFor: armedFor,
            ignoredStreak: model.ignoredStreak,
            restUntil: restUntil,
          ),
        ),
      );

  /// The row for [state]. Its armed time is written as an entry's `created_at` is, so it reads back
  /// as a local time with the wall-clock fields it was stored with.
  static NudgeStateModel toModel(NudgeState state) => NudgeStateModel(
        categoryId: state.categoryId,
        armedFor: state.armedFor.map((DateTime at) => at.toIso8601String()).toNullable(),
        ignoredStreak: state.ignoredStreak,
        restUntil: state.restUntil.map((CalendarDate day) => day.toIso()).toNullable(),
      );

  static Either<Failure, Option<CalendarDate>> _day(String? text) => Option<String>.fromNullable(text).match(
        () => Either<Failure, Option<CalendarDate>>.right(const Option<CalendarDate>.none()),
        (String text) => CalendarDate.parse(text).map(Option<CalendarDate>.of),
      );

  static Either<Failure, Option<DateTime>> _instant(String? text) => Option<String>.fromNullable(text).match(
        () => Either<Failure, Option<DateTime>>.right(const Option<DateTime>.none()),
        (String text) => Option<DateTime>.fromNullable(DateTime.tryParse(text))
            .toEither<Failure>(() => InvalidDataFailure('Bad armed_for "$text"'))
            .map(Option<DateTime>.of),
      );
}
