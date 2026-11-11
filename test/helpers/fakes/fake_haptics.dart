import 'package:hisaab/core/design/haptics.dart';

/// Records haptic events instead of buzzing, so tests can assert one effect per event.
final class FakeHaptics implements Haptics {
  final List<String> events = <String>[];

  @override
  Future<void> tick() async => events.add('tick');

  @override
  Future<void> success() async => events.add('success');

  @override
  Future<void> reject() async => events.add('reject');

  @override
  Future<void> threshold() async => events.add('threshold');
}
