/// How often a recurring rule repeats (SPEC BR-9).
enum Frequency {
  weekly,

  /// Every 14 days from the anchor date.
  biweekly,

  /// Same day each month, clamped to shorter months like paydays (SPEC BR-1).
  monthly,
  yearly,
}
