import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

/// One daily nudge to schedule: a quiet "anything to log?" reminder, with no amount or note.
final class NudgeNotice extends Equatable {
  const NudgeNotice({required this.id, required this.at, required this.categoryName});

  /// The notification id: scheduling the same id again replaces it, never duplicates it.
  final int id;

  /// When it shows, in local time.
  final DateTime at;

  /// The category it names; [None] is the general nudge.
  final Option<String> categoryName;

  /// Whether it is still ahead of [now]; the plugin refuses to schedule a past instant.
  bool isAfter(DateTime now) => at.isAfter(now);

  @override
  List<Object?> get props => <Object?>[id, at, categoryName];
}
