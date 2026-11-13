import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/widgets/polite_preview_slot.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

class _Harness extends StatefulWidget {
  const _Harness({super.key, this.debounce = PolitePreviewSlot.defaultDebounce});

  final Duration debounce;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String text = 'first';
  String stateClass = 'preview';

  void change({String? text, String? stateClass}) => setState(() {
        this.text = text ?? this.text;
        this.stateClass = stateClass ?? this.stateClass;
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PolitePreviewSlot(
          stateClass: stateClass,
          liveText: text,
          debounce: widget.debounce,
          child: Text(text),
        ),
      );
}

void main() {
  final GlobalKey<_HarnessState> key = GlobalKey<_HarnessState>();

  void withScreenReader(WidgetTester tester, {required bool on}) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(accessibleNavigation: on);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  group('PolitePreviewSlot (FR-KS-4 AC-4, D186)', () {
    testWidgets('with accessibleNavigation, text changes announce 1.2 s after the last change', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      withScreenReader(tester, on: true);
      await pumpApp(tester, _Harness(key: key));

      key.currentState!.change(text: 'second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.bySemanticsLabel('first'), findsOneWidget);
      expect(find.bySemanticsLabel('second'), findsNothing);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.bySemanticsLabel('second'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('each change restarts the wait, so only the last one is spoken', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      withScreenReader(tester, on: true);
      await pumpApp(tester, _Harness(key: key));

      key.currentState!.change(text: 'second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      key.currentState!.change(text: 'third');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.bySemanticsLabel('first'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.bySemanticsLabel('third'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a change of stateClass announces at once', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      withScreenReader(tester, on: true);
      await pumpApp(tester, _Harness(key: key));

      key.currentState!.change(text: 'cap line', stateClass: 'cap');
      await tester.pump();

      expect(find.bySemanticsLabel('cap line'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the slot is a polite live region', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      withScreenReader(tester, on: true);
      await pumpApp(tester, _Harness(key: key));

      expect(tester.getSemantics(find.bySemanticsLabel('first')).flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('without accessibleNavigation there is no live label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      withScreenReader(tester, on: false);
      await pumpApp(tester, _Harness(key: key));

      key.currentState!.change(text: 'second');
      await tester.pump(const Duration(milliseconds: 1300));

      expect(find.byType(Semantics).evaluate().where((Element e) => (e.widget as Semantics).properties.liveRegion ?? false), isEmpty);
      expect(find.text('second'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a zero debounce speaks on the next frame', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      withScreenReader(tester, on: true);
      await pumpApp(tester, _Harness(key: key, debounce: Duration.zero));

      key.currentState!.change(text: 'second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(find.bySemanticsLabel('second'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the timer is cancelled on dispose', (WidgetTester tester) async {
      withScreenReader(tester, on: true);
      await pumpApp(tester, _Harness(key: key));
      key.currentState!.change(text: 'second');

      await tester.pumpWidget(const SizedBox());

      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
