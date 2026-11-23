import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_motion.dart';
import '../../domain/entities/month_story.dart';
import 'story_art.dart';
import 'story_motif.dart';

/// The month story's full-window backdrop: the [page]'s line art edge to edge, behind the status
/// bar and past the 480dp story column, crossfading to the next page's art as the page turns
/// (D210). Each page's art starts its own course when it arrives.
class StoryBackdrop extends StatelessWidget {
  const StoryBackdrop({super.key, required this.page});

  final StoryPage page;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: HisaabMotion.reduceMotion(context) ? HisaabMotion.reducedCrossfade : HisaabMotion.resize,
        child: StoryArt(key: ValueKey<StoryPage>(page), motif: StoryMotif.forPage(page)),
      );
}
