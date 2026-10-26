import 'package:equatable/equatable.dart';

import '../../../core/errors/failure.dart';
import '../../domain/entities/spends_overview.dart';

/// What Spends shows.
sealed class SpendsState extends Equatable {
  const SpendsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load; the cards show without numbers.
final class SpendsLoading extends SpendsState {
  const SpendsLoading();
}

/// One cycle's [overview]. [savingLimits] is true while "Use these limits" is being saved, and
/// [limitsFailed] after that save failed (FR-SP-5).
final class SpendsReady extends SpendsState {
  const SpendsReady(this.overview, {this.savingLimits = false, this.limitsFailed = false});

  final SpendsOverview overview;
  final bool savingLimits;
  final bool limitsFailed;

  @override
  List<Object?> get props => <Object?>[overview, savingLimits, limitsFailed];
}

/// Loading failed; a quiet message with Try again.
final class SpendsFailed extends SpendsState {
  const SpendsFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
