import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../ledger/ledger.dart';
import 'category_spend.dart';

/// The pages of a month story, in the order they are shown (SPEC BR-20).
enum StoryPage { month, kept, whereItWent, days, against, end }

/// A look back at one finished cycle: what came in, where it went, its days and how it compares
/// with the cycle before (SPEC BR-20, FR-SP-7). Computed when it is shown, never stored.
final class MonthStory extends Equatable {
  const MonthStory({
    required this.cycle,
    required this.previous,
    required this.entryCount,
    required this.income,
    required this.saved,
    required this.bills,
    required this.everyday,
    required this.notLogged,
    required this.rows,
    required this.days,
    required this.comparison,
  });

  final PayCycle cycle;

  /// The cycle before [cycle], which page 5 names.
  final PayCycle previous;

  /// Entries of any kind dated in [cycle].
  final int entryCount;

  /// `I`: every *Got* in the cycle.
  final Money income;

  /// `Sv`: every *Saved* in the cycle.
  final Money saved;

  /// `B`: *Spent* posted by a rule, not *Not logged*.
  final Money bills;

  /// `E`: *Spent* the user typed, not *Not logged*.
  final Money everyday;

  /// `NL`: *Spent* *Not logged* fixes; money that went, but not *Spent* (BR-18).
  final Money notLogged;

  /// *Where it went*, as Spends shows it (BR-13).
  final List<CategorySpend> rows;

  /// Page 4; [None] with fewer than 7 days of *Everyday* spending.
  final Option<StoryDays> days;

  /// Page 5; [None] when the cycle before was not fully tracked or had no *Spent*.
  final Option<StoryComparison> comparison;

  /// Spends' own *Spent*: bills and everyday, without *Not logged* (FR-SP-4a).
  Money get spent => bills + everyday;

  /// `L`: what was left after spending, fixes and saving; negative past income.
  Money get left => income - bills - everyday - notLogged - saved;

  /// Whether anything came in, so page 2 has a bar and a headline.
  bool get hasIncome => income > Money.zero;

  /// The pages present, in order.
  List<StoryPage> get pages => <StoryPage>[
        StoryPage.month,
        StoryPage.kept,
        StoryPage.whereItWent,
        if (days.isSome()) StoryPage.days,
        if (comparison.isSome()) StoryPage.against,
        StoryPage.end,
      ];

  @override
  List<Object?> get props =>
      <Object?>[cycle, previous, entryCount, income, saved, bills, everyday, notLogged, rows, days, comparison];
}

/// Page 4: the cycle's *Everyday* spending day by day, against its daily share.
final class StoryDays extends Equatable {
  const StoryDays({
    required this.perDay,
    required this.share,
    required this.peakIndex,
    required this.peakNote,
    required this.peakCategoryId,
    required this.quietDays,
    required this.weekday,
  });

  /// One amount per day of the cycle; index 0 is its first day.
  final List<Money> perDay;

  /// `floor((I − Sv − B) / days)`; [None] when that is ₹0 or less.
  final Option<Money> share;

  /// The day with the most spending, the earliest on a tie.
  final int peakIndex;

  /// The note of that day's biggest entry, when it has one.
  final Option<String> peakNote;

  /// The category of that day's biggest entry, which names the day when there is no note.
  final int peakCategoryId;

  /// Days with nothing spent.
  final int quietDays;

  /// The weekday holding at least 35% of the spending, if one does.
  final Option<StoryWeekday> weekday;

  /// What the biggest day spent.
  Money get peak => perDay[peakIndex];

  @override
  List<Object?> get props => <Object?>[perDay, share, peakIndex, peakNote, peakCategoryId, quietDays, weekday];
}

/// "Your 5 Saturdays came to ₹15,840": a weekday, how many of it the cycle had, and their total.
final class StoryWeekday extends Equatable {
  const StoryWeekday({required this.weekday, required this.count, required this.total});

  /// [DateTime.monday] to [DateTime.sunday].
  final int weekday;
  final int count;
  final Money total;

  @override
  List<Object?> get props => <Object?>[weekday, count, total];
}

/// Page 5: the cycle's *Spent* against the cycle before, and the categories that moved most.
final class StoryComparison extends Equatable {
  const StoryComparison({required this.previousSpent, required this.change, required this.moves});

  final Money previousSpent;

  /// This cycle's *Spent* less the previous cycle's; negative when less was spent.
  final Money change;

  /// At most 3, biggest change first; never a ₹0 change.
  final List<CategoryMove> moves;

  @override
  List<Object?> get props => <Object?>[previousSpent, change, moves];
}

/// One category's change in *Spent* against the cycle before; negative when it fell.
final class CategoryMove extends Equatable {
  const CategoryMove({required this.category, required this.change});

  final Category category;
  final Money change;

  @override
  List<Object?> get props => <Object?>[category, change];
}
