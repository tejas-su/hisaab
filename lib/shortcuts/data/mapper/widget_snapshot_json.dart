import '../../../settings/settings.dart';
import '../../domain/entities/widget_snapshot.dart';

/// Turns a [WidgetSnapshot] into the JSON native code reads (widget spec §4). The keys and the
/// version are a contract with `SnapshotReader.kt`: change both together and bump [version].
abstract final class WidgetSnapshotJson {
  /// The format's version; the widget ignores a snapshot whose version it doesn't know.
  static const int version = 1;

  /// [snapshot] as a JSON-ready map.
  static Map<String, Object?> toJson(WidgetSnapshot snapshot) => <String, Object?>{
        'v': version,
        'writtenAt': snapshot.writtenAt.toIso8601String(),
        'look': _look(snapshot.look),
        'strings': <String, Object?>{
          'title': snapshot.strings.title,
          'add': snapshot.strings.add,
          'addSpoken': snapshot.strings.addSpoken,
          'setUp': snapshot.strings.setUp,
          'setUpBody': snapshot.strings.setUpBody,
        },
        'rows': snapshot.rows.map(_row).toList(),
      };

  static Map<String, Object?> _row(WidgetDay day) => <String, Object?>{
        'date': day.date.toIso(),
        'state': day.state.name,
        'hero': day.hero,
        'heroMuted': day.heroMuted,
        'over': day.over.toNullable(),
        'glance': day.glance,
        'range': day.range,
        'days': day.days,
        'daysLeft': day.daysLeft,
        'flag': day.flag,
        'bar': <String, Object?>{
          'style': day.bar.style.name,
          'left': day.bar.left,
          'bites': day.bar.bites,
          'tick': day.bar.tick.toNullable(),
        },
        'dots': <String, Object?>{'count': day.dots.count, 'style': day.dots.style.name},
        'spoken': day.spoken,
      };

  static String _look(ThemeChoice look) => switch (look) {
        ThemeChoice.matchPhone => 'system',
        ThemeChoice.light => 'light',
        ThemeChoice.dark => 'dark',
      };
}
