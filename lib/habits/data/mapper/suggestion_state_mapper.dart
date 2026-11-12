import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../domain/entities/suggestion_state.dart';
import '../model/suggestion_state_model.dart';

/// Converts between [SuggestionStateModel] rows and [SuggestionState] entities.
abstract final class SuggestionStateMapper {
  /// Returns [Right] with the state, or [Left] with `InvalidDataFailure` for a bad date or
  /// forgotten time.
  static Either<Failure, SuggestionState> toEntity(SuggestionStateModel model) => _day(model.quietOn).flatMap(
        (Option<CalendarDate> quietOn) => _day(model.restUntil).flatMap(
          (Option<CalendarDate> restUntil) => _instant(model.forgottenAt).map(
            (Option<DateTime> forgottenAt) => SuggestionState(
              categoryId: model.categoryId,
              quietOn: quietOn,
              restUntil: restUntil,
              forgottenAt: forgottenAt,
            ),
          ),
        ),
      );

  /// The row for [state]. Its forgotten time is written as an entry's `created_at` is, so the two
  /// read back as local times with the wall-clock fields they were stored with (E62).
  static SuggestionStateModel toModel(SuggestionState state) => SuggestionStateModel(
        categoryId: state.categoryId,
        quietOn: state.quietOn.map((CalendarDate day) => day.toIso()).toNullable(),
        restUntil: state.restUntil.map((CalendarDate day) => day.toIso()).toNullable(),
        forgottenAt: state.forgottenAt.map((DateTime at) => at.toIso8601String()).toNullable(),
      );

  static Either<Failure, Option<CalendarDate>> _day(String? text) => Option<String>.fromNullable(text).match(
        () => Either<Failure, Option<CalendarDate>>.right(const Option<CalendarDate>.none()),
        (String text) => CalendarDate.parse(text).map(Option<CalendarDate>.of),
      );

  static Either<Failure, Option<DateTime>> _instant(String? text) => Option<String>.fromNullable(text).match(
        () => Either<Failure, Option<DateTime>>.right(const Option<DateTime>.none()),
        (String text) => Option<DateTime>.fromNullable(DateTime.tryParse(text))
            .toEither<Failure>(() => InvalidDataFailure('Bad forgotten_at "$text"'))
            .map(Option<DateTime>.of),
      );
}
