import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Spends and Every entry states compare by their fields', () {
    final Failure failure = DatabaseFailure('locked');
    expect(const SpendsLoading().props, isEmpty);
    expect(SpendsFailed(failure).props, <Object?>[failure]);
    expect(const EntriesLoading().props, isEmpty);
    expect(EntriesFailed(failure).props, <Object?>[failure]);
  });
}
