import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';

import 'categories.dart';

/// A *Not logged* fix entry (BR-18): *Spent* in the hidden `not_logged` category, or *Got* in
/// `not_logged_in` when [got] is set; dated [date], with no rule.
Entry notLogged(int rupees, CalendarDate date, {int id = 800, bool got = false}) => Entry(
      id: id,
      amount: Money.fromMajor(rupees),
      kind: got ? EntryKind.got : EntryKind.spent,
      categoryId: got ? SeedCategoryIds.notLoggedIn : SeedCategoryIds.notLogged,
      date: date,
      createdAt: DateTime(date.year, date.month, date.day, 11),
      note: 'Not logged',
      isNotLogged: true,
    );
