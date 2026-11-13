import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/shortcuts/data/platform/android_shortcuts_platform.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel(AndroidShortcutsPlatform.channelName);
  final TestDefaultBinaryMessenger messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void answer(Object? Function(MethodCall call) reply) => messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        return reply(call);
      });

  setUp(() => calls = <MethodCall>[]);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('AndroidShortcutsPlatform', () {
    test('publishes the snapshot as JSON text', () async {
      answer((MethodCall _) => null);
      final WidgetSnapshot snapshot = WidgetSnapshot(
        writtenAt: DateTime(2026, 10, 26),
        look: ThemeChoice.dark,
        strings: const WidgetStrings(title: 'T', add: 'A', addSpoken: 'AS', setUp: 'S', setUpBody: 'SB'),
        rows: const <WidgetDay>[],
      );

      await AndroidShortcutsPlatform().publish(snapshot);

      expect(calls.single.method, 'publish');
      expect((jsonDecode(calls.single.arguments as String) as Map<String, Object?>)['look'], 'dark');
    });

    test('asks whether the widget and tile can be added, then adds them', () async {
      answer((MethodCall call) => call.method == 'canPinWidget' ? true : call.method == 'canAddTile' ? false : null);
      final AndroidShortcutsPlatform platform = AndroidShortcutsPlatform();

      expect(await platform.canPinWidget(), isTrue);
      expect(await platform.canAddTile(), isFalse);
      await platform.pinWidget();
      await platform.addTile();

      expect(calls.map((MethodCall c) => c.method), <String>['canPinWidget', 'canAddTile', 'pinWidget', 'addTile']);
    });

    test('reads the tap that started the app', () async {
      answer((MethodCall _) => 'hisaab://add');

      expect(await AndroidShortcutsPlatform().launchAction(), const Option<LaunchAction>.of(LaunchAction.add));
    });

    test('a channel error is swallowed: nothing can be added and no tap is read', () async {
      answer((MethodCall _) => throw PlatformException(code: 'boom'));
      final AndroidShortcutsPlatform platform = AndroidShortcutsPlatform();

      expect(await platform.canPinWidget(), isFalse);
      expect(await platform.canAddTile(), isFalse);
      expect(await platform.launchAction(), const Option<LaunchAction>.none());
      await expectLater(platform.pinWidget(), completes);
    });

    test('a null answer means the widget and tile cannot be added', () async {
      answer((MethodCall _) => null);
      final AndroidShortcutsPlatform platform = AndroidShortcutsPlatform();

      expect(await platform.canPinWidget(), isFalse);
      expect(await platform.canAddTile(), isFalse);
    });

    test('streams taps that native code reports while the app runs, and ignores anything else', () async {
      final AndroidShortcutsPlatform platform = AndroidShortcutsPlatform();
      final Future<List<LaunchAction>> heard = platform.launches.take(2).toList();
      Future<void> send(String method, Object? argument) =>
          messenger.handlePlatformMessage(channel.name, channel.codec.encodeMethodCall(MethodCall(method, argument)), (ByteData? _) {});

      await send('launch', 'hisaab://home');
      await send('launch', 42);
      await send('other', 'hisaab://add');
      await send('launch', 'hisaab://nowhere');
      await send('launch', 'hisaab://add');

      expect(await heard, <LaunchAction>[LaunchAction.home, LaunchAction.add]);
    });
  });
}
