import 'package:hisaab/ledger/domain/category_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryIcon.forName', () {
    const Map<String, String> picks = <String, String>{
      'Petrol': 'fuel',
      'petrol': 'fuel',
      'Kirana': 'groceries',
      'sabzi': 'vegetables',
      'Doodh': 'milk',
      'Cutting chai': 'chai',
      'Sutta': 'cigarettes',
      'beedi': 'cigarettes',
      'Daru': 'drinks',
      'Beer': 'beer',
      'Cold drink': 'cold_drink',
      'Paan': 'paan',
      'Hukka': 'hookah',
      'Auto': 'auto',
      'Ola': 'cab',
      'Riya school': 'school',
      'Kids': 'kids',
      'Pets': 'pet',
      'Salon': 'salon',
      'Gym': 'gym',
      'Netflix': 'movies',
      'Shaadi': 'wedding',
      'Shaadi gift': 'gift',
      'vada pav': 'snacks',
      'Eating out': 'eating_out',
      'Car wash': 'car',
    };
    for (final MapEntry<String, String> pick in picks.entries) {
      test('"${pick.key}" picks ${pick.value}', () {
        expect(CategoryIcon.forName(pick.key), pick.value);
      });
    }

    test('the first group with a word in the name wins, top to bottom', () {
      expect(CategoryIcon.forName('Car service'), 'car');
    });

    test('matches whole words only', () {
      expect(CategoryIcon.forName('Carrots'), CategoryIcon.fallback);
    });

    test('ignores punctuation, case and extra spaces', () {
      expect(CategoryIcon.forName('  KIDS!!  '), 'kids');
    });

    for (final String name in <String>['', '   ', 'Misc', '₹₹₹', 'चाय']) {
      test('"$name" has no match and falls back to tag', () {
        expect(CategoryIcon.forName(name), CategoryIcon.fallback);
      });
    }
  });

  group('CategoryIcon.keys', () {
    test('holds 51 distinct keys, the fallback last', () {
      expect(CategoryIcon.keys, hasLength(51));
      expect(CategoryIcon.keys.toSet(), hasLength(51));
      expect(CategoryIcon.keys.last, CategoryIcon.fallback);
    });

    test('never reuses a built-in category key, so a stored key has one meaning', () {
      const List<String> seeds = <String>[
        'food', 'travel', 'shopping', 'bills', 'fun', 'health', 'home', 'other', 'salary', 'other_income', 'saved',
        'card_paid',
      ];
      expect(CategoryIcon.keys.where(seeds.contains), isEmpty);
    });
  });
}
