import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/onboarding/data/repository/onboarding_draft_repository_impl.dart';
import 'package:hisaab/onboarding/domain/entities/onboarding_draft.dart';
import 'package:hisaab/onboarding/domain/entities/onboarding_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fakes/fake_app_preferences_repository.dart';

void main() {
  late FakeAppPreferencesRepository preferences;
  late OnboardingDraftRepositoryImpl repository;

  setUp(() {
    preferences = FakeAppPreferencesRepository();
    repository = OnboardingDraftRepositoryImpl(preferences: preferences);
  });

  group('OnboardingDraftRepositoryImpl', () {
    test('loads nothing on a fresh install', () async {
      expect(await repository.load().run(), Either<Failure, Option<OnboardingDraft>>.right(const Option<OnboardingDraft>.none()));
    });

    test('loads what it saved (FR-ON-6)', () async {
      final OnboardingDraft draft = OnboardingDraft(step: OnboardingStep.payday, income: Money.fromMajor(45000));
      await repository.save(draft).run();
      expect(await repository.load().run(), Either<Failure, Option<OnboardingDraft>>.right(Option<OnboardingDraft>.of(draft)));
    });

    test('an unreadable draft starts onboarding over instead of failing', () async {
      preferences.draftJson = '{broken';
      expect(await repository.load().run(), Either<Failure, Option<OnboardingDraft>>.right(const Option<OnboardingDraft>.none()));
    });

    test('passes a database failure through', () async {
      preferences.failure = DatabaseFailure('locked');
      expect((await repository.load().run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect((await repository.save(const OnboardingDraft()).run()).getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
