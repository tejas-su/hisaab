import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../bloc/entry_card_state.dart';
import 'entry_card_amount_part.dart';
import 'entry_card_category_part.dart';
import 'entry_card_day_part.dart';
import 'entry_card_naming_part.dart';

/// The part unfolded inside the entry card under its chips, one at a time (SPEC FR-AD-8 AC-2).
class EntryCardPart extends StatelessWidget {
  const EntryCardPart({super.key, required this.form});

  final EntryCardForm form;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(top: HisaabSpacing.m),
        child: form.part.match(
          () => const SizedBox.shrink(),
          (CardPart part) => switch (part) {
            CardPart.amount => EntryCardAmountPart(form: form),
            CardPart.category => EntryCardCategoryPart(form: form),
            CardPart.naming => EntryCardNamingPart(form: form),
            CardPart.day => EntryCardDayPart(form: form),
          },
        ),
      );
}
