import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shortcuts/shortcuts.dart';
import 'shortcut_rows_event.dart';
import 'shortcut_rows_state.dart';

/// Owns Settings' *Shortcuts* group (SPEC FR-SE-6): whether the phone can add the widget and the
/// tile, and asking Android to add one when its row is tapped. Driven by the Settings page.
class ShortcutRowsBloc extends Bloc<ShortcutRowsEvent, ShortcutRowsState> {
  ShortcutRowsBloc({required this._platform}) : super(const ShortcutRowsLoading()) {
    on<ShortcutRowsLoadRequested>(_onLoadRequested, transformer: restartable());
    // why: a second tap while Android's dialog is being asked for would ask twice.
    on<ShortcutRowsWidgetTapped>((ShortcutRowsWidgetTapped event, Emitter<ShortcutRowsState> emit) => _platform.pinWidget(), transformer: droppable());
    on<ShortcutRowsTileTapped>((ShortcutRowsTileTapped event, Emitter<ShortcutRowsState> emit) => _platform.addTile(), transformer: droppable());
  }

  final ShortcutsPlatform _platform;

  Future<void> _onLoadRequested(ShortcutRowsLoadRequested event, Emitter<ShortcutRowsState> emit) async {
    final bool widget = await _platform.canPinWidget();
    final bool tile = await _platform.canAddTile();
    emit(ShortcutRowsReady(canAddWidget: widget, canAddTile: tile));
  }
}
