import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// What was put into each saving and what was used from it, all time (BR-19, D175).
///
/// [bySaving] is keyed by the saving rule's id and holds only savings with a put-in or a use.
/// *Put in extra* (a *Saved* entry with no rule) belongs to no saving, so it is in no entry here (E100).
final class SavingTotals extends Equatable {
  const SavingTotals({this.bySaving = const <int, ({Money putIn, Money used})>{}, this.anyUse = false});

  /// Every *Saved* entry posted by the rule, and every *Used* entry linked to it.
  final Map<int, ({Money putIn, Money used})> bySaving;

  /// Whether any *Used* entry exists, even one whose saving was deleted (E98).
  final bool anyUse;

  @override
  List<Object?> get props => <Object?>[bySaving, anyUse];
}
