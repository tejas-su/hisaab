import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home states compare by their fields', () {
    expect(const HomeLoading().props, isEmpty);
    final Failure failure = DatabaseFailure('locked');
    expect(HomeFailed(failure).props, <Object?>[failure]);
  });
}
