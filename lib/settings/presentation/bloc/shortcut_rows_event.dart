import 'package:equatable/equatable.dart';

/// What happens in Settings' *Shortcuts* group (SPEC FR-SE-6).
sealed class ShortcutRowsEvent extends Equatable {
  const ShortcutRowsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Settings opened: find out which rows this phone can show.
final class ShortcutRowsLoadRequested extends ShortcutRowsEvent {
  const ShortcutRowsLoadRequested();
}

/// The user tapped *Add a widget*.
final class ShortcutRowsWidgetTapped extends ShortcutRowsEvent {
  const ShortcutRowsWidgetTapped();
}

/// The user tapped *Add to quick settings*.
final class ShortcutRowsTileTapped extends ShortcutRowsEvent {
  const ShortcutRowsTileTapped();
}
