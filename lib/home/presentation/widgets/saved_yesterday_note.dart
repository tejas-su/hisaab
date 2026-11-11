import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The morning note under the hero: "Yesterday was ₹300 under its share, so every day got ₹33 more"
/// (SPEC BR-8, UI_DESIGN §5.2). Drops the second half when each day gets under ₹1 more.
class SavedYesterdayNote extends StatelessWidget {
  const SavedYesterdayNote({super.key, required this.saving});

  final YesterdaySaving saving;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    String spoken(Money amount) => strings.spokenAmount(context.money.digits(amount));
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: AppIcon(AppIcons.onTrack, size: 18, color: context.colors.ink2),
          ),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(
            child: Text(
              _words(strings, context.money.format),
              semanticsLabel: _words(strings, spoken),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
            ),
          ),
        ],
      ),
    );
  }

  String _words(AppLocalizations strings, String Function(Money) amount) => saving.eachDayMore.isZero
      ? strings.savedYesterdayOnly(amount(saving.saved))
      : strings.savedYesterday(amount(saving.saved), amount(saving.eachDayMore));
}
