import 'package:equatable/equatable.dart';

/// What happens on the *Fix my number* sheet (SPEC FR-FX).
sealed class FixEvent extends Equatable {
  const FixEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The sheet opened, Try again was tapped, or the ledger changed behind it: read hisaab's figure.
final class FixLoadRequested extends FixEvent {
  const FixLoadRequested();
}

/// A digit key ([key] is '0'–'9' or '00').
final class FixKeyPressed extends FixEvent {
  const FixKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// ⌫: drop the last digit; the last one leaves the amount empty.
final class FixBackspacePressed extends FixEvent {
  const FixBackspacePressed();
}

/// A long-press on ⌫: empty the amount.
final class FixCleared extends FixEvent {
  const FixCleared();
}

/// *Fix it*: post the entry, or open the guard when the gap is large.
final class FixSavePressed extends FixEvent {
  const FixSavePressed();
}

/// The guard's answer: *Yes, add …* when [yes], *No, some is older* otherwise.
final class FixGuardAnswered extends FixEvent {
  const FixGuardAnswered({required this.yes});

  final bool yes;

  @override
  List<Object?> get props => <Object?>[yes];
}

/// Back, system back or Escape: from the guard it steps back like *No*; on the keypad it does
/// nothing, because the page itself closes.
final class FixBackPressed extends FixEvent {
  const FixBackPressed();
}
