import 'package:flutter/foundation.dart';

/// One short message for a [HisaabSnackbarHost], with an optional [action] such as Undo.
@immutable
class HisaabSnackbar {
  const HisaabSnackbar({required this.message, this.semanticsLabel, this.action});

  final String message;

  /// What a screen reader says instead of [message], such as an amount in words.
  final String? semanticsLabel;
  final HisaabSnackbarAction? action;
}

/// The one control a [HisaabSnackbar] can carry; [onPressed] runs once and the bar closes.
@immutable
class HisaabSnackbarAction {
  const HisaabSnackbarAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}
