import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../domain/entities/suggestion_state.dart';
import '../../domain/repository/suggestion_state_repository.dart';
import '../datasource/suggestion_state_local_data_source.dart';
import '../mapper/suggestion_state_mapper.dart';
import '../model/suggestion_state_model.dart';

/// [SuggestionStateRepository] over sqflite.
final class SuggestionStateRepositoryImpl implements SuggestionStateRepository {
  /// Reads and writes through [_source].
  const SuggestionStateRepositoryImpl({required this._source});

  final SuggestionStateLocalDataSource _source;

  @override
  TaskEither<Failure, Map<int, SuggestionState>> all() => dbTask(_source.all)
      .chainEither((List<SuggestionStateModel> models) => models.traverseEither(SuggestionStateMapper.toEntity))
      .map(
        (List<SuggestionState> states) =>
            <int, SuggestionState>{for (final SuggestionState state in states) state.categoryId: state},
      );

  @override
  TaskEither<Failure, Option<SuggestionState>> of(int categoryId) =>
      dbTask(() => _source.byCategory(categoryId)).chainEither(
        (SuggestionStateModel? model) => Option<SuggestionStateModel>.fromNullable(model).match(
          () => Either<Failure, Option<SuggestionState>>.right(const Option<SuggestionState>.none()),
          (SuggestionStateModel model) => SuggestionStateMapper.toEntity(model).map(Option<SuggestionState>.of),
        ),
      );

  @override
  TaskEither<Failure, Unit> put(SuggestionState state) =>
      dbTask(() => _source.upsert(SuggestionStateMapper.toModel(state))).map((void _) => unit);

  @override
  TaskEither<Failure, Unit> markAsked(int categoryId, CalendarDate day) =>
      dbTask(() => _source.setAskedOn(categoryId, day.toIso())).map((void _) => unit);

  @override
  TaskEither<Failure, Unit> remove(int categoryId) => dbTask(() => _source.delete(categoryId)).map((int _) => unit);
}
