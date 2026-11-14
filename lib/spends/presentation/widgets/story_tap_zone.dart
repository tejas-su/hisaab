import 'package:material_ui/material_ui.dart';

/// An invisible half of a month story page that turns it (SPEC FR-SP-7 AC-3). It is a real button
/// named [label], so TalkBack, Switch Access and a keyboard reach it; disabled when [onTap] is null.
class StoryTapZone extends StatelessWidget {
  const StoryTapZone({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        onTap: onTap,
        child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: onTap),
      );
}
