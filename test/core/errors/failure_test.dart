import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/logging/app_logger.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('DatabaseFailure keeps the error text', () {
      expect(DatabaseFailure(StateError('locked')).message, contains('locked'));
    });

    test('failures with the same type and message are equal', () {
      expect(const InvalidDataFailure('bad'), const InvalidDataFailure('bad'));
    });

    test('separately created failures compare by type and message', () {
      final Object error = StateError('disk full');
      expect(DatabaseFailure(error), DatabaseFailure(error));
      expect(DatabaseFailure(error).hashCode, DatabaseFailure(error).hashCode);
      expect(DatabaseFailure(StateError('a')) == DatabaseFailure(StateError('b')), isFalse);
    });

    test('failures of different types are not equal even with the same message', () {
      expect(DatabaseFailure('x') == const InvalidDataFailure('x'), isFalse);
    });
  });

  group('NoParams', () {
    test('all instances are equal and have no props', () {
      expect(const NoParams(), const NoParams());
      expect(const NoParams().props, isEmpty);
    });
  });

  group('AppLogger', () {
    test('log and recordError never throw', () {
      expect(() => AppLogger.log(tag: 'test', data: <String, Object?>{'count': 1}), returnsNormally);
      expect(() => AppLogger.recordError(StateError('boom'), StackTrace.current), returnsNormally);
    });
  });
}
