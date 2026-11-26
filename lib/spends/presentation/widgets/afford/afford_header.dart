import 'package:material_ui/material_ui.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/widgets/hisaab_back_button.dart';

/// The *Can I afford it?* sheet's top row: Back and the [title] ("Can I afford it?", then the
/// item's name and price beside the shopping glyph once [showsItem]) (UI_DESIGN 5.4a).
class AffordHeader extends StatelessWidget {
  const AffordHeader({super.key, required this.title, required this.spokenTitle, this.showsItem = false});

  final String title;

  /// What TalkBack reads for [title], with amounts spoken.
  final String spokenTitle;
  final bool showsItem;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.s),
        child: Row(
          children: <Widget>[
            const HisaabBackButton(),
            const SizedBox(width: HisaabSpacing.s),
            if (showsItem) ...<Widget>[
              // why: the glyph is decoration beside the item's own name.
              ExcludeSemantics(child: AppIcon(AppIcons.forKey('shopping'))),
              const SizedBox(width: HisaabSpacing.s),
            ],
            Expanded(
              child: Semantics(
                container: true,
                header: true,
                label: spokenTitle,
                excludeSemantics: true,
                child: Text(title, key: const ValueKey<String>('afford-title'), style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
          ],
        ),
      );
}
