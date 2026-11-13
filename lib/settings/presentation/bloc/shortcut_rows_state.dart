import 'package:equatable/equatable.dart';

/// Which of Settings' *Shortcuts* rows show (SPEC FR-SE-6).
sealed class ShortcutRowsState extends Equatable {
  const ShortcutRowsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Still asking the phone; the group isn't shown yet.
final class ShortcutRowsLoading extends ShortcutRowsState {
  const ShortcutRowsLoading();
}

/// The phone answered: each row shows only when it can do its job (AC-1, AC-2); with neither,
/// the group is hidden (AC-3).
final class ShortcutRowsReady extends ShortcutRowsState {
  const ShortcutRowsReady({required this.canAddWidget, required this.canAddTile});

  final bool canAddWidget;
  final bool canAddTile;

  /// Whether the group shows at all.
  bool get any => canAddWidget || canAddTile;

  @override
  List<Object?> get props => <Object?>[canAddWidget, canAddTile];
}
