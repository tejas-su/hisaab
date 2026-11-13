/// Shortcuts feature: the home-screen widget's day-by-day snapshot, the launch actions of the
/// widget, Quick Settings tile and app shortcut, and the platform that serves them (SPEC FR-WG).
library;

export 'di/shortcuts_module.dart';
export 'domain/entities/launch_action.dart';
export 'domain/entities/projected_day.dart';
export 'domain/entities/widget_snapshot.dart';
export 'domain/repository/shortcuts_platform.dart';
export 'domain/usecase/project_widget_days.dart';
export 'presentation/widget_snapshot_mapper.dart';
