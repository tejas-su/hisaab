import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/theme_choice.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/theme_event.dart';
import '../bloc/theme_state.dart';
import 'look_choice.dart';
import 'look_switch.dart';

/// The *Look* card of Settings (SPEC FR-SE-3, D130): one row with *Light or dark* and the current
/// look's name, and a [LookSwitch] at its end (under the words when a word can't fit beside it).
/// One tap sends [ThemePicked] to [themeBloc], and the whole app changes look at once.
class LookGroup extends StatelessWidget {
  const LookGroup({super.key, required this.themeBloc});

  final ThemeBloc themeBloc;

  @override
  Widget build(BuildContext context) => Material(
        key: const ValueKey<String>('look-tile'),
        color: context.colors.surface,
        shape: HisaabShapes.squircle(HisaabRadii.card),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter, vertical: HisaabSpacing.m),
          child: BlocBuilder<ThemeBloc, ThemeState>(
            bloc: themeBloc,
            builder: (BuildContext context, ThemeState state) => LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget words = _words(context, state.choice);
                final Widget toggle =
                    LookSwitch(picked: state.choice, onPicked: (ThemeChoice choice) => themeBloc.add(ThemePicked(choice)));
                return _wordsFitBeside(context, state.choice, constraints.maxWidth)
                    ? Row(spacing: HisaabSpacing.m, children: <Widget>[Expanded(child: words), toggle])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: HisaabSpacing.m, children: <Widget>[words, toggle]);
              },
            ),
          ),
        ),
      );

  // why: beside the toggle the words may wrap, but a word must never break; at large text on a
  // narrow phone the toggle moves under them instead.
  bool _wordsFitBeside(BuildContext context, ThemeChoice current, double width) {
    final TextTheme text = Theme.of(context).textTheme;
    final double room = width - LookSwitch.width - HisaabSpacing.m;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final Iterable<(String, TextStyle?)> words = <(String, TextStyle?)>[
      (AppLocalizations.of(context).lookTile, text.bodyLarge),
      (LookChoice.of(context, current).label, text.bodyMedium),
    ].expand(((String, TextStyle?) line) => line.$1.split(' ').map((String word) => (word, line.$2)));
    return words.every(((String, TextStyle?) word) => _width(word.$1, word.$2, scaler, direction) <= room);
  }

  static double _width(String word, TextStyle? style, TextScaler scaler, TextDirection direction) {
    final TextPainter painter = TextPainter(text: TextSpan(text: word, style: style), textScaler: scaler, textDirection: direction)
      ..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  Widget _words(BuildContext context, ThemeChoice current) {
    final TextTheme text = Theme.of(context).textTheme;
    // why: the buttons already speak their own names; the row's words would be read twice.
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AppLocalizations.of(context).lookTile, style: text.bodyLarge),
          Text(LookChoice.of(context, current).label, style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
        ],
      ),
    );
  }
}
