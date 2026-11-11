import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('CalendarDate', () {
    test('drops the time of day', () {
      expect(CalendarDate.fromDateTime(DateTime(2026, 10, 26, 23, 59)), const CalendarDate(2026, 10, 26));
    });

    test('adds days across month and year ends', () {
      expect(const CalendarDate(2026, 10, 31).addDays(1), const CalendarDate(2026, 11, 1));
      expect(const CalendarDate(2026, 12, 31).addDays(1), const CalendarDate(2027, 1, 1));
      expect(const CalendarDate(2026, 3, 1).addDays(-1), const CalendarDate(2026, 2, 28));
    });

    test('counts days between dates, independent of daylight saving', () {
      expect(const CalendarDate(2026, 10, 26).daysUntil(const CalendarDate(2026, 11, 3)), 8);
      expect(const CalendarDate(2026, 3, 1).daysUntil(const CalendarDate(2026, 4, 1)), 31);
      expect(const CalendarDate(2026, 11, 3).daysUntil(const CalendarDate(2026, 10, 26)), -8);
    });

    test('knows month lengths, including leap Februaries', () {
      expect(CalendarDate.daysInMonth(2027, 2), 28);
      expect(CalendarDate.daysInMonth(2028, 2), 29);
      expect(CalendarDate.daysInMonth(2100, 2), 28);
      expect(CalendarDate.daysInMonth(2000, 2), 29);
      expect(CalendarDate.daysInMonth(2026, 9), 30);
    });

    test('reports the ISO weekday', () {
      expect(const CalendarDate(2026, 10, 26).weekday, DateTime.monday);
      expect(const CalendarDate(2026, 10, 31).weekday, DateTime.saturday);
    });

    test('orders chronologically', () {
      expect(const CalendarDate(2026, 10, 26).isBefore(const CalendarDate(2026, 10, 27)), isTrue);
      expect(const CalendarDate(2026, 10, 27).isAfter(const CalendarDate(2026, 10, 26)), isTrue);
      expect(const CalendarDate(2026, 10, 26).compareTo(const CalendarDate(2026, 10, 26)), 0);
    });

    test('round-trips through ISO-8601 text for storage', () {
      expect(const CalendarDate(2026, 1, 5).toIso(), '2026-01-05');
      expect(CalendarDate.parse('2026-01-05'), Either<Failure, CalendarDate>.right(const CalendarDate(2026, 1, 5)));
    });

    test('parse returns InvalidDataFailure for malformed text', () {
      for (final String text in <String>['2026-1-5x', '', '05-01-2026', '2026-01-05 ']) {
        expect(CalendarDate.parse(text).getLeft().toNullable(), isA<InvalidDataFailure>(), reason: text);
      }
    });

    test('parse rejects well-formed but impossible dates', () {
      expect(CalendarDate.parse('2026-02-30').isLeft(), isTrue);
    });

    test('validate rejects impossible dates and accepts leap days', () {
      expect(CalendarDate.validate(2026, 2, 30).isLeft(), isTrue);
      expect(CalendarDate.validate(2026, 13, 1).isLeft(), isTrue);
      expect(CalendarDate.validate(2026, 0, 1).isLeft(), isTrue);
      expect(CalendarDate.validate(2026, 1, 0).isLeft(), isTrue);
      expect(CalendarDate.validate(2028, 2, 29), Either<Failure, CalendarDate>.right(const CalendarDate(2028, 2, 29)));
    });

    test('toString is the ISO form', () {
      expect(const CalendarDate(2026, 10, 26).toString(), '2026-10-26');
    });
  });
}
