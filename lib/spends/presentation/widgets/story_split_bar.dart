import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/month_story.dart';
import 'split_bar_painter.dart';

/// Page 2's split bar and its key (SPEC BR-20, FR-SP-7): Bills, Saved, Everyday (with *Not logged*),
/// then left over or past what came in. Hidden from screen readers; the page's sentence says it.
class StorySplitBar extends StatelessWidget {
  const StorySplitBar({super.key, required this.story});

  final MonthStory story;

  static const double _height = 28;
  static const double _swatch = 14;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool over = story.left.isNegative;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: _height,
            child: CustomPaint(painter: SplitBarPainter(amounts: _amounts, colours: _colours(context))),
          ),
          const SizedBox(height: HisaabSpacing.m),
          _key(context, _Swatch.solid, strings.storyKeyBills, story.bills),
          if (!story.saved.isZero) _key(context, _Swatch.outline, strings.storyKeySaved, story.saved),
          _key(context, _Swatch.soft, strings.storyKeyEveryday, story.everyday),
          if (!story.notLogged.isZero) _key(context, _Swatch.soft, strings.storyKeyNotLogged, story.notLogged),
          over
              ? _key(context, _Swatch.hatch, strings.storyKeyMoreThanCameIn, Money.zero - story.left)
              : _key(context, _Swatch.track, strings.storyKeyLeftOver, story.left),
        ],
      ),
    );
  }

  SplitAmounts get _amounts => (
        bills: story.bills.amountMinor,
        saved: story.saved.amountMinor,
        everyday: (story.everyday + story.notLogged).amountMinor,
        income: story.income.amountMinor,
      );

  static SplitColours _colours(BuildContext context) =>
      (ink: context.colors.ink, ink2: context.colors.ink2, soft: context.colors.ink2, sunk: context.colors.sunk, gap: context.colors.background);

  Widget _key(BuildContext context, _Swatch swatch, String label, Money amount) {
    final TextTheme type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.xs),
      child: Row(
        children: <Widget>[
          _swatchBox(context, swatch),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(child: Text(label, style: type.bodyMedium?.copyWith(color: context.colors.ink2))),
          Text(context.money.format(amount), style: type.titleMedium?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  Widget _swatchBox(BuildContext context, _Swatch swatch) => Container(
        width: _swatch,
        height: _swatch * 0.8,
        decoration: BoxDecoration(
          color: switch (swatch) {
            _Swatch.solid || _Swatch.hatch => context.colors.ink,
            _Swatch.soft => context.colors.ink2,
            _Swatch.outline => context.colors.background,
            _Swatch.track => context.colors.sunk,
          },
          border: switch (swatch) {
            _Swatch.outline => Border.all(color: context.colors.ink, width: 2),
            _Swatch.track => Border.all(color: context.colors.ink2),
            _Swatch.solid || _Swatch.soft || _Swatch.hatch => null,
          },
          borderRadius: BorderRadius.circular(HisaabRadii.block / 2),
        ),
      );
}

/// How a key row's swatch is drawn, matching its part of the bar.
enum _Swatch { solid, outline, soft, track, hatch }
