import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_back_button.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_spend.dart';
import '../../domain/entities/month_story.dart';
import 'story_against_page.dart';
import 'story_days_page.dart';
import 'story_end_page.dart';
import 'story_kept_page.dart';
import 'story_month_page.dart';
import 'story_outlined_button.dart';
import 'story_progress.dart';
import 'story_tap_zone.dart';
import 'story_where_page.dart';

/// The month story's pages, one at a time (SPEC FR-SP-7): progress and Back on top, the page in the
/// middle with its two tap zones, and on the last page *Ask an AI* and *Done* below. Nothing moves
/// on by itself (AC-3).
class MonthStoryView extends StatefulWidget {
  const MonthStoryView({super.key, required this.story, required this.cycleLabel, required this.previousLabel, required this.onAskAi, required this.onDone});

  final MonthStory story;
  final String cycleLabel;
  final String previousLabel;
  final VoidCallback onAskAi;
  final VoidCallback onDone;

  @override
  State<MonthStoryView> createState() => _MonthStoryViewState();
}

class _MonthStoryViewState extends State<MonthStoryView> {
  int _index = 0;

  /// A horizontal fling faster than this turns the page.
  static const double _flingVelocity = 200;

  List<StoryPage> get _pages => widget.story.pages;

  void _go(int delta) {
    final int next = (_index + delta).clamp(0, _pages.length - 1);
    if (next != _index) {
      setState(() => _index = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool last = _index == _pages.length - 1;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(context, strings),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (DragEndDetails details) => _fling(details.primaryVelocity ?? 0),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: _page(context)),
                    Positioned.fill(child: _zones(strings)),
                  ],
                ),
              ),
            ),
            if (last) _actions(strings),
          ],
        ),
      ),
    );
  }

  void _fling(double velocity) {
    if (velocity.abs() >= _flingVelocity) {
      _go(velocity < 0 ? 1 : -1);
    }
  }

  Widget _header(BuildContext context, AppLocalizations strings) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, HisaabSpacing.s, HisaabSpacing.gutter, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StoryProgress(count: _pages.length, current: _index),
            Row(
              children: <Widget>[
                const HisaabBackButton(),
                const SizedBox(width: HisaabSpacing.s),
                Expanded(
                  child: Text(
                    strings.storyProgress(widget.cycleLabel, _index + 1, _pages.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // why: the zones sit over the page so a tap anywhere moves on, but a vertical drag still
  // scrolls the page beneath, since a tap loses the gesture arena to a drag.
  Widget _zones(AppLocalizations strings) => Row(
        children: <Widget>[
          Expanded(child: StoryTapZone(key: const ValueKey<String>('story-back'), label: strings.storyPreviousPage, onTap: _index == 0 ? null : () => _go(-1))),
          Expanded(
            flex: 2,
            child: StoryTapZone(
              key: const ValueKey<String>('story-next'),
              label: strings.storyNextPage,
              onTap: _index == _pages.length - 1 ? null : () => _go(1),
            ),
          ),
        ],
      );

  Widget _page(BuildContext context) {
    final bool reduce = HisaabMotion.reduceMotion(context);
    return AnimatedSwitcher(
      duration: reduce ? HisaabMotion.reducedCrossfade : HisaabMotion.resize,
      switchInCurve: HisaabMotion.easeOut,
      transitionBuilder: (Widget child, Animation<double> animation) => reduce
          ? FadeTransition(opacity: animation, child: child)
          : FadeTransition(
              opacity: animation,
              child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation), child: child),
            ),
      child: KeyedSubtree(key: ValueKey<StoryPage>(_pages[_index]), child: _pageFor(_pages[_index])),
    );
  }

  Widget _pageFor(StoryPage page) => switch (page) {
        StoryPage.month => StoryMonthPage(story: widget.story, cycleLabel: widget.cycleLabel),
        StoryPage.kept => StoryKeptPage(story: widget.story),
        StoryPage.whereItWent => StoryWherePage(story: widget.story),
        StoryPage.days => widget.story.days.match(
            () => const SizedBox.shrink(),
            (StoryDays days) => StoryDaysPage(story: widget.story, days: days, categories: _categories),
          ),
        StoryPage.against => widget.story.comparison.match(
            () => const SizedBox.shrink(),
            (StoryComparison against) => StoryAgainstPage(against: against, previousLabel: widget.previousLabel),
          ),
        StoryPage.end => StoryEndPage(story: widget.story, cycleLabel: widget.cycleLabel),
      };

  Map<int, Category> get _categories => <int, Category>{for (final CategorySpend row in widget.story.rows) row.category.id: row.category};

  Widget _actions(AppLocalizations strings) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SignalKey(key: const ValueKey<String>('story-ask-ai'), label: strings.askAiCardTitle(widget.cycleLabel), onPressed: widget.onAskAi),
            const SizedBox(height: HisaabSpacing.s),
            StoryOutlinedButton(key: const ValueKey<String>('story-done'), label: strings.done, onPressed: widget.onDone),
          ],
        ),
      );
}
