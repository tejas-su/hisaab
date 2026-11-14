import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// The month story's progress: one thin bar per page present, `ink` up to [current] and
/// `hairline` after it (SPEC FR-SP-7 AC-3). Hidden from screen readers; the header says "2 of 6".
class StoryProgress extends StatelessWidget {
  const StoryProgress({super.key, required this.count, required this.current});

  final int count;

  /// The page shown, from 0.
  final int current;

  static const double _height = 3;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Row(
          children: <Widget>[
            for (int page = 0; page < count; page++) ...<Widget>[
              if (page > 0) const SizedBox(width: HisaabSpacing.xs),
              Expanded(
                child: Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: page <= current ? context.colors.ink : context.colors.hairline,
                    borderRadius: BorderRadius.circular(_height),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}
