/// Which way money moved: out of the pocket (*Spent*), into it (*Got*), or put into a saving
/// (*Saved*, D120) (SPEC §2).
enum EntryKind {
  spent,
  got,

  /// Money put into a saving such as an RD; reserved before its day, never counted as spending.
  saved,
}
