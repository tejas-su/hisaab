import 'package:equatable/equatable.dart';

import '../../../core/errors/failure.dart';
import '../../domain/entities/month_story.dart';

/// What the month story route shows.
sealed class MonthStoryState extends Equatable {
  const MonthStoryState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loading: the dark page with its close button and nothing else.
final class MonthStoryLoading extends MonthStoryState {
  const MonthStoryLoading();
}

/// The [story], page by page.
final class MonthStoryReady extends MonthStoryState {
  const MonthStoryReady(this.story);

  final MonthStory story;

  @override
  List<Object?> get props => <Object?>[story];
}

/// The cycle no longer has a story, because entries were deleted since the card showed; the
/// route closes.
final class MonthStoryGone extends MonthStoryState {
  const MonthStoryGone();
}

/// Loading failed; a quiet message with Try again.
final class MonthStoryFailed extends MonthStoryState {
  const MonthStoryFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
