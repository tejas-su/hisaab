import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/errors/failure.dart';
import '../../domain/entities/nudge_state.dart';
import '../../domain/repository/nudge_state_repository.dart';
import '../datasource/nudge_state_local_data_source.dart';
import '../mapper/nudge_state_mapper.dart';
import '../model/nudge_state_model.dart';

/// [NudgeStateRepository] over sqflite.
final class NudgeStateRepositoryImpl implements NudgeStateRepository {
  /// Reads and writes through [_source].
  const NudgeStateRepositoryImpl({required this._source});

  final NudgeStateLocalDataSource _source;

  @override
  TaskEither<Failure, Map<int, NudgeState>> all() => dbTask(_source.all)
      .chainEither((List<NudgeStateModel> models) => models.traverseEither(NudgeStateMapper.toEntity))
      .map((List<NudgeState> states) => <int, NudgeState>{for (final NudgeState state in states) state.categoryId: state});

  @override
  TaskEither<Failure, Unit> put(NudgeState state) =>
      dbTask(() => _source.upsert(NudgeStateMapper.toModel(state))).map((void _) => unit);

  @override
  TaskEither<Failure, Unit> clear() => dbTask(_source.deleteAll).map((void _) => unit);
}
