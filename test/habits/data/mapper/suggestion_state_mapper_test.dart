import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/data/mapper/suggestion_state_mapper.dart';
import 'package:hisaab/habits/data/model/suggestion_state_model.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';

final SuggestionState _full = SuggestionState(
  categoryId: 13,
  quietOn: const Option<CalendarDate>.of(CalendarDate(2026, 10, 26)),
  restUntil: const Option<CalendarDate>.of(CalendarDate(2026, 11, 25)),
  forgottenAt: Option<DateTime>.of(DateTime(2026, 10, 26, 10, 5, 30, 250)),
);

const SuggestionStateModel _fullModel = SuggestionStateModel(
  categoryId: 13,
  quietOn: '2026-10-26',
  restUntil: '2026-11-25',
  forgottenAt: '2026-10-26T10:05:30.250',
);

SuggestionState _entityOf(SuggestionStateModel model) =>
    SuggestionStateMapper.toEntity(model).getOrElse((Failure failure) => fail(failure.message));

void main() {
  group('SuggestionStateMapper', () {
    test('round-trips every field', () {
      expect(SuggestionStateMapper.toModel(_full), _fullModel);
      expect(_entityOf(_fullModel), _full);
    });

    test('round-trips a state with nothing set', () {
      const SuggestionState empty = SuggestionState(categoryId: 1);

      expect(SuggestionStateMapper.toModel(empty), const SuggestionStateModel(categoryId: 1));
      expect(_entityOf(const SuggestionStateModel(categoryId: 1)), empty);
    });

    test('round-trips dates across New Year and on 29 February', () {
      const SuggestionState state = SuggestionState(
        categoryId: 1,
        quietOn: Option<CalendarDate>.of(CalendarDate(2027, 12, 31)),
        restUntil: Option<CalendarDate>.of(CalendarDate(2028, 2, 29)),
      );

      expect(SuggestionStateMapper.toModel(state).restUntil, '2028-02-29');
      expect(_entityOf(SuggestionStateMapper.toModel(state)), state);
    });

    final Map<String, SuggestionStateModel> badModels = <String, SuggestionStateModel>{
      'a quiet_on that is not a date': const SuggestionStateModel(categoryId: 1, quietOn: '26 Oct'),
      'a quiet_on that does not exist': const SuggestionStateModel(categoryId: 1, quietOn: '2026-02-30'),
      'a rest_until that is not a date': const SuggestionStateModel(categoryId: 1, restUntil: ''),
      'a bad forgotten_at': const SuggestionStateModel(categoryId: 1, forgottenAt: 'yesterday'),
      'an empty forgotten_at': const SuggestionStateModel(categoryId: 1, forgottenAt: ''),
    };
    for (final MapEntry<String, SuggestionStateModel> bad in badModels.entries) {
      test('${bad.key} is InvalidDataFailure', () {
        expect(SuggestionStateMapper.toEntity(bad.value).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }

    test('forgotten_at keeps its wall-clock fields (E62)', () {
      final DateTime forgottenAt = _entityOf(_fullModel).forgottenAt.getOrElse(() => fail('no forgotten_at'));

      expect(forgottenAt.isUtc, isFalse);
      expect(
        <int>[forgottenAt.year, forgottenAt.month, forgottenAt.day, forgottenAt.hour, forgottenAt.minute, forgottenAt.second],
        <int>[2026, 10, 26, 10, 5, 30],
      );
    });

    test('forgotten_at is stored in the form of an entry\'s created_at', () {
      final DateTime tappedAt = DateTime(2026, 10, 26, 10, 5);

      final SuggestionStateModel model =
          SuggestionStateMapper.toModel(SuggestionState(categoryId: 1, forgottenAt: Option<DateTime>.of(tappedAt)));

      expect(model.forgottenAt, tappedAt.toIso8601String());
      expect(model.forgottenAt, '2026-10-26T10:05:00.000');
    });

    test('an entry logged at the stored moment is not before it', () {
      final DateTime forgottenAt = _entityOf(_fullModel).forgottenAt.getOrElse(() => fail('no forgotten_at'));

      expect(DateTime.parse('2026-10-26T10:05:30.250').isBefore(forgottenAt), isFalse);
      expect(DateTime.parse('2026-10-26T10:05:30.249').isBefore(forgottenAt), isTrue);
    });
  });
}
