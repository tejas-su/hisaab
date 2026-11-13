import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// A text slot that a screen reader announces politely, without nagging (FR-KS-4 AC-4, D186).
///
/// Under TalkBack it is a live region whose spoken text follows [liveText] **1.2 s after the last
/// change**, so a person typing digits hears the final preview once; when [stateClass] changes
/// (say, a preview giving way to a cap line) the new text is spoken at once. Without a screen
/// reader it is just [child].
///
/// [child] is the slot's full, focusable text; [liveText] is what is spoken, which may be shorter.
class PolitePreviewSlot extends StatefulWidget {
  const PolitePreviewSlot({
    super.key,
    required this.stateClass,
    required this.liveText,
    required this.child,
    this.debounce = defaultDebounce,
  });

  /// How long the text must stay unchanged before it is spoken (FR-KS-4 AC-4).
  static const Duration defaultDebounce = Duration(milliseconds: 1200);

  /// Names the kind of text now shown (preview, cap line, nothing left). A change speaks at once.
  final Object stateClass;

  /// The text to speak.
  final String liveText;

  /// What is drawn.
  final Widget child;

  /// How long [liveText] must be stable before it is spoken; tests pass [Duration.zero].
  final Duration debounce;

  @override
  State<PolitePreviewSlot> createState() => _PolitePreviewSlotState();
}

class _PolitePreviewSlotState extends State<PolitePreviewSlot> {
  late String _spoken = widget.liveText;
  Timer? _timer;

  @override
  void didUpdateWidget(PolitePreviewSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stateClass != oldWidget.stateClass) {
      _timer?.cancel();
      _spoken = widget.liveText;
      return;
    }
    if (widget.liveText != oldWidget.liveText) {
      _timer?.cancel();
      _timer = Timer(widget.debounce, _speakLatest);
    }
  }

  void _speakLatest() {
    if (mounted) {
      setState(() => _spoken = widget.liveText);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MediaQuery.accessibleNavigationOf(context)) {
      return widget.child;
    }
    return Semantics(liveRegion: true, label: _spoken, excludeSemantics: true, child: widget.child);
  }
}
