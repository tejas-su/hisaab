import 'package:expense_tracker/app/cubit/launch_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launch states compare by their fields', () {
    expect(const LaunchLoading().props, isEmpty);
    expect(const LaunchReady(assemble: true).props, <Object?>[true]);
    final Failure failure = DatabaseFailure('locked');
    expect(LaunchFailed(failure).props, <Object?>[failure]);
    expect(LaunchFailed(failure), LaunchFailed(failure));
  });
}
