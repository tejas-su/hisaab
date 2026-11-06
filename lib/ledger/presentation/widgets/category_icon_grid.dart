import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../category_icon_groups.dart';

/// The curated category icons in their groups, each with its word under it; tapping one picks it
/// (FR-AD-9 AC-3, FR-SE-2, D138).
///
/// [picked] is shown filled with a check; [suggested], the key the name picks, is announced as
/// "from the name". Lay it out inside a scroll view; it sizes to its content.
class CategoryIconGrid extends StatelessWidget {
  const CategoryIconGrid({super.key, required this.picked, required this.onPicked, this.suggested});

  final String picked;
  final String? suggested;
  final ValueChanged<String> onPicked;

  static const int _columns = 4;
  static const double _cellHeight = 64;
  static const double _gap = HisaabSpacing.s;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (String group, List<String> keys) in CategoryIconGroups.all) ...<Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.xs, HisaabSpacing.m, HisaabSpacing.xs, HisaabSpacing.s),
            child: Semantics(
              header: true,
              child: Text(strings.categoryIconGroup(group), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.ink2)),
            ),
          ),
          for (int row = 0; row * _columns < keys.length; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: _gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int column = 0; column < _columns; column++) ...<Widget>[
                  if (column > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: row * _columns + column < keys.length ? _cell(context, strings, keys[row * _columns + column]) : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _cell(BuildContext context, AppLocalizations strings, String key) {
    final bool isPicked = key == picked;
    final String word = strings.categoryIconName(key);
    final Color ink = isPicked ? context.colors.background : context.colors.ink;
    return Pressable(
      key: ValueKey<String>('icon-$key'),
      semanticLabel: key == suggested ? strings.categoryIconFromNameShort(word) : word,
      selected: isPicked,
      onPressed: () => onPicked(key),
      focusRadius: HisaabRadii.key,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: _cellHeight),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.xs, vertical: HisaabSpacing.s),
        decoration: ShapeDecoration(
          color: isPicked ? context.colors.ink2 : (pressed ? context.colors.hairline : context.colors.sunk),
          shape: HisaabShapes.squircle(HisaabRadii.key),
        ),
        child: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppIcon(AppIcons.forKey(key), color: ink),
                  const SizedBox(height: 2),
                  Text(
                    word,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ink),
                  ),
                ],
              ),
            ),
            if (isPicked) PositionedDirectional(top: 0, end: 0, child: AppIcon(AppIcons.check, size: 14, color: ink)),
          ],
        ),
      ),
    );
  }
}
