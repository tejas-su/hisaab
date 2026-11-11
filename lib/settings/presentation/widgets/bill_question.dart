import 'package:material_ui/material_ui.dart';

/// The top of a bill editor step: the question as a heading, then the step's own [children].
class BillQuestion extends StatelessWidget {
  const BillQuestion({super.key, required this.question, this.children = const <Widget>[]});

  final String question;
  final List<Widget> children;

  @override
  // why: full width, so a short question and amount start at the gutter under the back button
  // instead of being centred by the step's layout.
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(question, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 30, height: 34 / 30)),
            ),
            ...children,
          ],
        ),
      );
}
