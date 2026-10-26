import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/domain/usecase/apply_suggested_limits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

void main() {
  late FakeCategoryRepository categories;
  final Map<int, Money> limits = <int, Money>{
    SeedCategoryIds.food: Money.fromMajor(10000),
    SeedCategoryIds.home: Money.fromMajor(8500),
  };

  setUp(() => categories = FakeCategoryRepository());

  group('ApplySuggestedLimits (BR-12)', () {
    test('saves every suggested limit in one write', () async {
      expect(await ApplySuggestedLimits(categories: categories)(limits).run(), Either<Failure, Unit>.right(unit));
      expect(categories.savedLimits, <Map<int, Money>>[limits]);
    });

    test('returns DatabaseFailure when the write fails', () async {
      categories.failure = DatabaseFailure('locked');
      expect((await ApplySuggestedLimits(categories: categories)(limits).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
