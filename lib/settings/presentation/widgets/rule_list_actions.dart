import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../../ledger/presentation/rule_words.dart';

/// The Bills or Savings page's pinned actions (FR-SE-1, D136): the marigold *Add a bill* /
/// *Add a saving* key, and on Savings the *Put in extra* chip under it.
///
/// [onAdd] opens the editor; [onPutInExtra] opens the *Put in extra* keypad and, when null,
/// leaves the chip out. In a short window the two share one row so the pinned area stays small.
class RuleListActions extends StatelessWidget {
  const RuleListActions({super.key, required this.kind, required this.onAdd, this.onPutInExtra});

  final EntryKind kind;
  final VoidCallback onAdd;
  final VoidCallback? onPutInExtra;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final Widget add = SignalKey(
      key: const ValueKey<String>('add-bill'),
      label: strings.ruleAdd(kind),
      icon: AppIcons.add,
      onPressed: onAdd,
    );
    final VoidCallback? putIn = onPutInExtra;
    if (putIn == null) {
      return add;
    }
    final Widget chip = HisaabChip(
      key: const ValueKey<String>('put-in-extra'),
      label: strings.putInExtra,
      icon: AppIcons.saving,
      expand: true,
      onPressed: putIn,
    );
    if (context.layout.heightClass == HeightClass.compact) {
      // why: stretched to the key's height, the chip shares its top and bottom edges.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: HisaabSpacing.s,
          children: <Widget>[
            Expanded(child: add),
            Expanded(child: chip),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        add,
        const SizedBox(height: HisaabSpacing.s),
        chip,
      ],
    );
  }
}
