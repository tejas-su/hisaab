import 'package:material_ui/material_ui.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/widgets/hisaab_back_button.dart';

/// One step of the *When it comes* question: Back and the [question], then its [body]. Back
/// returns one step through the sheet's `PopScope` (SPEC FR-SE-1, D140).
class IncomeStepFrame extends StatelessWidget {
  const IncomeStepFrame({super.key, required this.question, required this.body});

  final String question;
  final Widget body;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const HisaabBackButton(),
              const SizedBox(width: HisaabSpacing.s),
              Expanded(child: Semantics(header: true, child: Text(question, style: Theme.of(context).textTheme.titleLarge))),
            ],
          ),
          const SizedBox(height: HisaabSpacing.m),
          body,
        ],
      );
}
