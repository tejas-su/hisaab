import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_cap_ring.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/shake.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';
import 'entry_card_words.dart';

/// The entry card's top: the category's glyph, the amount, and the category and day chips, each a
/// button that unfolds its part (SPEC FR-AD-8 AC-1, AC-2). A changed value carries a check.
class EntryCardHeader extends StatelessWidget {
  const EntryCardHeader({super.key, required this.form, required this.rejections});

  final EntryCardForm form;

  /// Refused keys so far, for the shake and the cap ring (FR-AD-2).
  final int rejections;

  static const double _well = 46;
  static const double _underline = 2;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final EntryCardBloc bloc = context.read<EntryCardBloc>();
    final List<CardChange> changes = form.changes;
    final Category? category = form.categories.where((Category c) => c.id == form.categoryId).firstOrNull;
    final String categoryName = EntryCardWords.category(context, form.categories, form.categoryId);
    final String day = EntryCardWords.day(context, form.date, form.today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: _well,
              height: _well,
              alignment: Alignment.center,
              decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.chip)),
              child: AppIcon(AppIcons.forKey(category?.iconKey ?? '')),
            ),
            const SizedBox(width: HisaabSpacing.m),
            Flexible(child: _amount(context, strings, bloc)),
            if (changes.contains(CardChange.amount)) const _ChangedMark(),
          ],
        ),
        const SizedBox(height: HisaabSpacing.s),
        Wrap(
          spacing: HisaabSpacing.s,
          runSpacing: HisaabSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            HisaabChip(
              key: const ValueKey<String>('entry-card-category'),
              onSurface: true,
              label: categoryName,
              icon: AppIcons.forKey(category?.iconKey ?? ''),
              trailingIcon: changes.contains(CardChange.category) ? AppIcons.check : AppIcons.dropdown,
              selected: form.part == const Option<CardPart>.of(CardPart.category) || form.part == const Option<CardPart>.of(CardPart.naming),
              semanticLabel: strings.entryCardFor(categoryName),
              onPressed: () => bloc.add(const EntryCardPartTapped(CardPart.category)),
            ),
            HisaabChip(
              key: const ValueKey<String>('entry-card-day'),
              onSurface: true,
              label: day,
              icon: AppIcons.calendar,
              trailingIcon: changes.contains(CardChange.day) ? AppIcons.check : AppIcons.dropdown,
              selected: form.part == const Option<CardPart>.of(CardPart.day),
              semanticLabel: strings.entryCardDay(day),
              onPressed: () => bloc.add(const EntryCardPartTapped(CardPart.day)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _amount(BuildContext context, AppLocalizations strings, EntryCardBloc bloc) {
    final bool open = form.part == const Option<CardPart>.of(CardPart.amount);
    final bool picked = open && form.typed.isNone();
    final Money shown = Money.fromMajor(form.shownRupees);
    return Pressable(
      key: const ValueKey<String>('entry-card-amount'),
      semanticLabel: strings.entryCardAmount(strings.spokenAmount(context.money.digits(shown))),
      semanticHint: strings.entryCardChangeHint,
      selected: open,
      focusRadius: HisaabRadii.block,
      onPressed: () => bloc.add(const EntryCardPartTapped(CardPart.amount)),
      builder: (BuildContext context, bool pressed) => AmountCapRing(
        rejections: rejections,
        amount: shown,
        child: Shake(
          trigger: rejections,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.xs),
            decoration: BoxDecoration(
              color: picked ? context.colors.sunk : null,
              border: Border(bottom: BorderSide(color: open ? context.colors.ink : context.colors.ink2, width: _underline)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(shown, roll: !open, style: Theme.of(context).textTheme.displaySmall),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small check beside a value the card has changed; it is the change's mark, not its colour.
class _ChangedMark extends StatelessWidget {
  const _ChangedMark();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsetsDirectional.only(start: HisaabSpacing.s),
        child: ExcludeSemantics(child: AppIcon(AppIcons.check, size: 18)),
      );
}
