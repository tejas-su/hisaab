import 'package:equatable/equatable.dart';

/// The finished prompt and what the preview says about it (SPEC BR-15, FR-AI-3).
final class PromptText extends Equatable {
  const PromptText({required this.text, required this.entryCount, required this.groupedWeeks});

  /// Plain UTF-8 text, byte-identical for the same input.
  final String text;

  /// Entries in the period, including any grouped by week.
  final int entryCount;

  /// How many of the oldest weeks were summarised to keep [text] within 12,000 characters;
  /// 0 when nothing was.
  final int groupedWeeks;

  @override
  List<Object?> get props => <Object?>[text, entryCount, groupedWeeks];
}
