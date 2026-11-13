/// The common savings offered as name pills when adding one, in display order (D120).
///
/// The first four never move. The last three are yearly costs (AC-Y1): money put in a twelfth a
/// month and *Used* when the cost falls due, so they get a caption on the amount question.
enum SavingKind {
  rd,
  sip,
  goldScheme,
  chit,
  insurance,
  schoolFees,
  festival;

  /// Whether this is a cost paid once a year (Insurance, School fees, Festival).
  bool get isYearlyCost => index >= SavingKind.insurance.index;
}
