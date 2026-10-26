import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failure.dart';

/// Contract every feature use case implements: one operation behind a single [call].
abstract interface class UseCase<T, Params> {
  /// Runs the operation; Left is a [Failure], Right is the result.
  TaskEither<Failure, T> call(Params params);
}

/// Parameters for a use case that needs none.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => <Object?>[];
}
