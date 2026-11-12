import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// An entry just saved by one tap on the *your usual* pill, which the app offers to undo
/// (SPEC BR-10, FR-AD-10).
final class UsualAdd extends Equatable {
  /// Pairs the saved [entry] with the [category] it went into.
  const UsualAdd({required this.entry, required this.category});

  /// The entry the tap saved; Undo deletes it.
  final Entry entry;

  /// The category as the tray showed it, for "Added ₹20 to Chai".
  final Category category;

  @override
  List<Object?> get props => <Object?>[entry, category];
}
