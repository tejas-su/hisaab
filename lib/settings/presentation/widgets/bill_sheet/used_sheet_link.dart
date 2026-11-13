import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_state.dart';
import '../../bloc/used_bloc.dart';
import '../../bloc/used_event.dart';
import '../../bloc/used_state.dart';

/// Connects a saving's sheet to its [UsedBloc] (blocs never reference each other): opening the
/// *Used* question loads it, going back drops unsaved typing, and a finished save closes the
/// whole sheet. Needs a [BillSheetBloc] and a [UsedBloc] above it.
class UsedSheetLink extends StatelessWidget {
  const UsedSheetLink({super.key, required this.child});

  final Widget child;

  static const Option<BillAnswer> _usedOpen = Option<BillAnswer>.of(BillAnswer.used);

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: <BlocListener<dynamic, dynamic>>[
          BlocListener<BillSheetBloc, BillSheetState>(
            listenWhen: (BillSheetState previous, BillSheetState current) =>
                previous is BillSheetReady && current is BillSheetReady && (previous.open == _usedOpen) != (current.open == _usedOpen),
            listener: (BuildContext context, BillSheetState state) {
              final UsedBloc used = context.read<UsedBloc>();
              if (state is BillSheetReady && state.open == _usedOpen) {
                used.add(UsedLoadRequested(state.rule));
              } else {
                used.add(const UsedReset());
              }
            },
          ),
          BlocListener<UsedBloc, UsedState>(
            listenWhen: (UsedState previous, UsedState current) => current is UsedDone,
            listener: (BuildContext context, UsedState state) => Navigator.of(context).pop(),
          ),
        ],
        child: child,
      );
}
