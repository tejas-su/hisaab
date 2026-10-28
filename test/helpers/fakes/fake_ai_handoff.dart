import 'dart:async';

import 'package:expense_tracker/ask_ai/domain/ai_handoff.dart';

/// Records every hand-off instead of touching the clipboard, browser or share sheet.
final class FakeAiHandoff implements AiHandoff {
  final List<String> copied = <String>[];
  final List<Uri> opened = <Uri>[];
  final List<String> shared = <String>[];

  /// What [open] answers; false acts like a phone with no browser.
  bool openResult = true;

  /// When set, the next [copy] waits for it, so a test can tap again mid-hand-off.
  Completer<void>? nextCopyGate;

  @override
  Future<void> copy(String text) async {
    copied.add(text);
    final Completer<void>? gate = nextCopyGate;
    nextCopyGate = null;
    await gate?.future;
  }

  @override
  Future<bool> open(Uri link) async {
    opened.add(link);
    return openResult;
  }

  @override
  Future<void> share(String text) async => shared.add(text);
}
