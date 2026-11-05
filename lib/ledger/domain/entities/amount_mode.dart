/// How a bill's amount behaves from month to month (D123).
enum AmountMode {
  /// The same every month; the engine posts it on its day. Savings and income are always fixed.
  fixed,

  /// Changes every month (electricity); it waits on its day for the user to say how much,
  /// reserved meanwhile at its estimate, the last amount entered.
  varies,

  /// A credit card bill: it waits to be recorded as paid but is never counted, because the card
  /// buys were counted when they were made.
  card,
}
