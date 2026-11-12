import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/hisaab_snackbar.dart';
import '../../../core/widgets/hisaab_snackbar_host.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/usual_add.dart';
import '../bloc/habits_bloc.dart';
import '../bloc/habits_event.dart';
import '../bloc/habits_state.dart';

/// Shows "Added ₹20 to Chai" with *Undo* over [child] after a one-tap add from the *your usual*
/// pill (SPEC BR-10, FR-AD-10 AC-4).
///
/// Wrap the page in view with it, below a [HabitsBloc]. The bar sits at the bottom edge of
/// [child], stays 4 s (until dismissed with TalkBack on), and Undo adds
/// [HabitsUsualUndoRequested].
class UsualAddedNotice extends StatelessWidget {
  /// Wraps [child], the page the bar shows over.
  const UsualAddedNotice({super.key, required this.child});

  /// The page in view: Home or Spends.
  final Widget child;

  @override
  Widget build(BuildContext context) => HisaabSnackbarHost(
        bottom: 0,
        child: BlocListener<HabitsBloc, HabitsState>(
          listener: (BuildContext context, HabitsState state) {
            if (state case HabitsReady(added: Some<UsualAdd>(value: final UsualAdd added))) {
              _offerUndo(context, added);
            }
          },
          child: child,
        ),
      );

  static void _offerUndo(BuildContext context, UsualAdd added) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final HabitsBloc bloc = context.read<HabitsBloc>();
    final String name = added.category.labelIn(strings);
    HisaabSnackbarHost.of(context).show(
      HisaabSnackbar(
        message: strings.usualAdded(context.money.format(added.entry.amount), name),
        semanticsLabel: strings.usualAdded(strings.spokenAmount(context.money.digits(added.entry.amount)), name),
        action: HisaabSnackbarAction(label: strings.undo, onPressed: () => bloc.add(HabitsUsualUndoRequested(added))),
      ),
    );
  }
}
