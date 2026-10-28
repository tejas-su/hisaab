/// What the user wants the AI to do with their data (SPEC BR-15, FR-AI-1).
enum AskGoal {
  reviewMonth,
  helpMeSave,
  makeBudget,
  onTrack,

  /// The user's own question, typed in a 200-character field.
  ownQuestion,
}

/// How much history the prompt carries (SPEC BR-15, FR-AI-2).
enum AskPeriod {
  /// The cycle Spends was showing (default).
  thisCycle(1),

  /// That cycle and the two before it.
  lastThreeCycles(3);

  const AskPeriod(this.cycleCount);

  /// How many cycles, newest first, the period covers.
  final int cycleCount;
}
