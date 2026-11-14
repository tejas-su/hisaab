/// Fix my number: the sheet where the user types how much of this cycle's money is left and
/// hisaab adds one *Not logged* entry for the difference (SPEC BR-18, FR-FX). Exposes the sheet and
/// the blocs `AppRoutes` wires to its three doors; the maths lives in the ledger.
library;

export 'presentation/bloc/fix_bloc.dart';
export 'presentation/bloc/fix_event.dart';
export 'presentation/bloc/fix_state.dart';
export 'presentation/bloc/fix_undo_bloc.dart';
export 'presentation/bloc/fix_undo_event.dart';
export 'presentation/bloc/fix_undo_state.dart';
export 'presentation/pages/fix_sheet.dart';
export 'presentation/widgets/fix_undo_listener.dart';
