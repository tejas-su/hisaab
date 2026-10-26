import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// What the typed amount does to today, e.g. "₹1,020 over today's share · tomorrow ₹1,722"
/// (SPEC FR-AD-3). Keeps its height when empty so the keypad never jumps.
class SpendPreviewLine extends StatelessWidget {
  const SpendPreviewLine({super.key, required this.preview});

  final Option<SpendPreview> preview;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: (style?.fontSize ?? 15) * (style?.height ?? 1.3)),
      child: Text(preview.match(() => '', (SpendPreview p) => _words(context, p)), style: style, textAlign: TextAlign.center),
    );
  }

  static String _words(BuildContext context, SpendPreview preview) {
    final AppLocalizations strings = AppLocalizations.of(context);
    String amount(Money money) => context.money.format(money);
    return switch (preview) {
      FitsToday(:final Money left) => strings.leavesForToday(amount(left)),
      OverTodayShare(:final Money over, :final Option<Money> tomorrow) => tomorrow.match(
          () => strings.overTodayShare(amount(over)),
          (Money share) => '${strings.overTodayShare(amount(over))}${strings.separator}${strings.tomorrowShare(amount(share))}',
        ),
    };
  }
}
