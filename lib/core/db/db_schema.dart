/// Table names; the only place they are spelled out.
abstract final class Tables {
  static const String categories = 'categories';
  static const String recurring = 'recurring';
  static const String transactions = 'transactions';
  static const String settings = 'settings';
}

/// Columns of [Tables.categories].
abstract final class CategoryColumns {
  static const String id = 'id';

  /// Stable seed key; also the l10n key for the default name.
  static const String key = 'key';

  /// User rename; null shows the localised default name.
  static const String customName = 'custom_name';
  static const String iconKey = 'icon_key';
  static const String kind = 'kind';

  /// Optional monthly limit in minor units (SPEC BR-12).
  static const String budgetMinor = 'budget_minor';
  static const String sort = 'sort';
  static const String archived = 'archived';
}

/// Columns of [Tables.recurring].
abstract final class RecurringColumns {
  static const String id = 'id';
  static const String label = 'label';
  static const String amountMinor = 'amount_minor';
  static const String currency = 'currency';
  static const String kind = 'kind';
  static const String categoryId = 'category_id';
  static const String frequency = 'freq';

  /// First occurrence, `YYYY-MM-DD`; its day of month or weekday anchors the schedule.
  static const String anchorDate = 'anchor_date';

  /// 1 when a monthly rule falls on the last day of every month.
  static const String lastDayOfMonth = 'last_day_of_month';
  static const String nextDue = 'next_due';
  static const String active = 'active';

  /// 1 for the salary rule that defines pay cycles (DECISIONS D20); at most one is active.
  static const String isIncomeSource = 'is_income_source';
}

/// Columns of [Tables.transactions] (an "entry" in the UI; never called a transaction there).
abstract final class TransactionColumns {
  static const String id = 'id';
  static const String amountMinor = 'amount_minor';
  static const String currency = 'currency';
  static const String kind = 'kind';
  static const String categoryId = 'category_id';
  static const String date = 'date';
  static const String note = 'note';
  static const String recurringId = 'recurring_id';
  static const String createdAt = 'created_at';
}

/// Columns of [Tables.settings].
abstract final class SettingsColumns {
  static const String key = 'key';
  static const String value = 'value';
}

/// Keys stored in [Tables.settings], grouped by owner (DECISIONS D20).
abstract final class SettingKeys {
  /// Ledger-owned.
  static const String currency = 'currency';
  static const String monthStart = 'month_start';
  static const String keepAsideMinor = 'keep_aside_minor';

  /// Settings-feature-owned.
  static const String themeMode = 'theme_mode';
  static const String onboardingDone = 'onboarding_done';
  static const String onboardingDraft = 'onboarding_draft';
}

/// Stored values of the `kind` column.
abstract final class EntryKindValues {
  static const String spent = 'out';
  static const String got = 'in';
}

/// Stored values of [RecurringColumns.frequency].
abstract final class FrequencyValues {
  static const String weekly = 'weekly';
  static const String biweekly = 'biweekly';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';
}
