import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/month_story.dart';
import '../entities/spends_overview.dart';
import 'get_spends_overview.dart';

/// Loads the month story of the cycle [call]'s params cycles before the current one (SPEC BR-20).
///
/// It reads the story off [GetSpendsOverview], so the story and Spends never disagree.
final class GetMonthStory implements UseCase<Option<MonthStory>, int> {
  const GetMonthStory({required this._overview});

  final GetSpendsOverview _overview;

  /// Returns [Right] with the story, or [None] inside it when BR-20 gives that cycle none; [Left]
  /// with `DatabaseFailure` or `InvalidDataFailure` when a read fails.
  @override
  TaskEither<Failure, Option<MonthStory>> call(int params) => _overview(params).map((SpendsOverview o) => o.story);
}
