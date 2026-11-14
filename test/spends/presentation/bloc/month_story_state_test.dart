// ignore_for_file: prefer_const_constructors (equality is tested on separate, non-canonical instances)
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/spends/domain/month_story_rules.dart';
import 'package:hisaab/spends/presentation/bloc/month_story_event.dart';
import 'package:hisaab/spends/presentation/bloc/month_story_state.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';

void main() {
  group('MonthStoryState equality', () {
    test('states with the same values are equal; different ones are not', () {
      expect(MonthStoryLoading(), MonthStoryLoading());
      expect(MonthStoryLoading(), isNot(MonthStoryGone()));
      expect(MonthStoryReady(SeptemberStory.story()), MonthStoryReady(SeptemberStory.story()));
      expect(MonthStoryReady(SeptemberStory.story()), isNot(MonthStoryReady(SeptemberStory.story(previousTracked: false))));
      expect(MonthStoryFailed(DatabaseFailure('locked')), MonthStoryFailed(DatabaseFailure('locked')));
    });
  });

  group('MonthStoryEvent equality', () {
    test('two load requests are equal', () {
      expect(MonthStoryLoadRequested(), MonthStoryLoadRequested());
    });
  });

  group('StoryWindow equality', () {
    test('windows over the same entries are equal', () {
      StoryWindow window({bool tracked = true}) => StoryWindow(
            cycle: SeptemberStory.september,
            previous: SeptemberStory.august,
            entries: SeptemberStory.septemberEntries(),
            previousEntries: SeptemberStory.augustEntries(),
            previousTracked: tracked,
            categories: seedCategories,
          );
      expect(window(), window());
      expect(window(), isNot(window(tracked: false)));
    });
  });
}
