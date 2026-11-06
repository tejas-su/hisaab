import 'package:equatable/equatable.dart';

/// What moves the *Delete everything* page (SPEC FR-SE-4 AC-6..8).
sealed class DeleteEverythingEvent extends Equatable {
  const DeleteEverythingEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The hold key was held full and let go, or armed and activated again with TalkBack.
final class DeleteEverythingConfirmed extends DeleteEverythingEvent {
  const DeleteEverythingConfirmed();
}
