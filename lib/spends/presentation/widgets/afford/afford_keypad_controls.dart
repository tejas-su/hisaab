import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/widgets/keypad.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../bloc/afford_bloc.dart';
import '../../bloc/afford_event.dart';

/// The shared keypad of steps 1 and 2 under the step's one marigold key, labelled [label]; a null
/// [action] greys the key.
class AffordKeypadControls extends StatelessWidget {
  const AffordKeypadControls({
    super.key,
    required this.keyHeight,
    required this.label,
    required this.actionKey,
    required this.action,
  });

  final double keyHeight;
  final String label;

  /// The marigold key's own key, for tests.
  final Key actionKey;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final AffordBloc bloc = context.read<AffordBloc>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Keypad(
          keyHeight: keyHeight,
          onKey: (String key) => bloc.add(AffordKeyPressed(key)),
          onBackspace: () => bloc.add(const AffordBackspacePressed()),
          onClear: () => bloc.add(const AffordCleared()),
        ),
        const SizedBox(height: HisaabSpacing.m),
        SignalKey(key: actionKey, label: label, onPressed: action),
      ],
    );
  }
}
