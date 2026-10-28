import 'package:expense_tracker/ask_ai/data/system_ai_handoff.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemAiHandoff.copy', () {
    test('puts the exact text on the clipboard', () async {
      final List<Object?> copied = <Object?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall call,
      ) async {
        if (call case MethodCall(method: 'Clipboard.setData', arguments: <Object?, Object?>{'text': final Object? text})) {
          copied.add(text);
        }
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await const SystemAiHandoff().copy('Task: Review my month.\n2026-10-26,60,spent,Food,"Rice, dal"');

      expect(copied, <Object?>['Task: Review my month.\n2026-10-26,60,spent,Food,"Rice, dal"']);
    });
  });
}
