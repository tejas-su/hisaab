/// Which way money moved: out of the pocket (*Spent*), into it (*Got*), put into a saving
/// (*Saved*, D120), or paid from a saving (*Used*, D175) (SPEC §2).
enum EntryKind {
  spent,
  got,

  /// Money put into a saving such as an RD; reserved before its day, never counted as spending.
  saved,

  /// A credit card bill paid: recorded so it can be tracked, never counted, because the card buys
  /// were counted when they were made (D123).
  cardPaid,

  /// Money paid for a cost out of a saving, such as a yearly insurance bill (BR-19). It touches no
  /// number: the money was counted when it was put in.
  used,
}
