import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../ledger/ledger.dart';
import '../bloc/entry_card_bloc.dart';
import '../bloc/entry_card_event.dart';
import '../bloc/entry_card_state.dart';

/// Lets a list of entries open them as cards in place (SPEC FR-AD-8): provides [bloc] to the rows
/// below, and turns Back into *Done* while a card is open (AC-9).
///
/// [partsInline] says whether a card unfolds its parts inside itself; it is false where a board
/// beside the list holds them (AC-12). A page without a scope keeps its rows as they are.
class EntryCardScope extends StatelessWidget {
  const EntryCardScope({super.key, required this.bloc, required this.child, this.partsInline = true});

  final EntryCardBloc bloc;
  final bool partsInline;
  final Widget child;

  /// The nearest scope's data, or null when the page has none.
  static EntryCardScopeData? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_ScopeData>()?.data;

  @override
  Widget build(BuildContext context) => BlocProvider<EntryCardBloc>.value(
        value: bloc,
        child: _ScopeData(
          data: EntryCardScopeData(bloc: bloc, partsInline: partsInline),
          child: BlocBuilder<EntryCardBloc, EntryCardState>(
            buildWhen: (EntryCardState previous, EntryCardState current) => (previous is EntryCardClosed) != (current is EntryCardClosed),
            builder: (BuildContext context, EntryCardState state) => PopScope(
              canPop: state is EntryCardClosed,
              onPopInvokedWithResult: (bool didPop, Object? _) {
                if (!didPop) {
                  bloc.add(const EntryCardDone());
                }
              },
              child: child,
            ),
          ),
        ),
      );
}

/// What a scope gives the rows below it.
final class EntryCardScopeData {
  const EntryCardScopeData({required this.bloc, required this.partsInline});

  final EntryCardBloc bloc;
  final bool partsInline;

  /// Opens [entry] as a card, closing (and writing) any card already open (AC-1).
  void open(Entry entry, {required Iterable<Category> categories, Option<CycleSummary> summary = const Option<CycleSummary>.none()}) =>
      bloc.add(EntryCardOpened(entry, categories: categories.toList(), summary: summary));
}

class _ScopeData extends InheritedWidget {
  const _ScopeData({required this.data, required super.child});

  final EntryCardScopeData data;

  @override
  bool updateShouldNotify(_ScopeData oldWidget) => data.bloc != oldWidget.data.bloc || data.partsInline != oldWidget.data.partsInline;
}
