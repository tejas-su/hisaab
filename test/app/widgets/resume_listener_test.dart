import 'package:expense_tracker/app/widgets/resume_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumeListener (BR-8)', () {
    testWidgets('calls onResume when the app comes back to the foreground', (WidgetTester tester) async {
      int resumes = 0;
      await tester.pumpWidget(ResumeListener(onResume: () => resumes++, child: const SizedBox()));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(resumes, 1);
    });

    testWidgets('does not call onResume when the app goes to the background', (WidgetTester tester) async {
      int resumes = 0;
      await tester.pumpWidget(ResumeListener(onResume: () => resumes++, child: const SizedBox()));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(resumes, 0);
    });

    testWidgets('stops listening when removed', (WidgetTester tester) async {
      int resumes = 0;
      await tester.pumpWidget(ResumeListener(onResume: () => resumes++, child: const SizedBox()));
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(resumes, 0);
    });
  });
}
