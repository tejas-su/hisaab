/// CSV helpers for the prompt's entries table (SPEC BR-15).
abstract final class PromptCsv {
  static final RegExp _needsQuotes = RegExp('[,"\n\r]');

  /// [value] as one RFC 4180 field: quoted, with inner quotes doubled, when it holds a comma,
  /// a quote or a line break; unchanged otherwise.
  static String field(String value) => value.contains(_needsQuotes) ? '"${value.replaceAll('"', '""')}"' : value;
}
