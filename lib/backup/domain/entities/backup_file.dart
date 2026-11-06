import 'package:equatable/equatable.dart';

import '../../../core/time/calendar_date.dart';

/// Every table row of hisaab at one moment, as stored (SPEC BR-16). The rows are opaque to the
/// domain: only the data layer reads their columns.
final class BackupFile extends Equatable {
  const BackupFile({required this.schemaVersion, required this.madeOn, required this.tables, required this.entryCount});

  /// The database schema version the rows are shaped for.
  final int schemaVersion;

  /// The day the backup was made, shown in the restore dialog.
  final CalendarDate madeOn;

  /// Rows by table name, each row as column → value.
  final Map<String, List<Map<String, Object?>>> tables;

  /// How many entries the backup holds, shown in the restore dialog.
  final int entryCount;

  @override
  List<Object?> get props => <Object?>[schemaVersion, madeOn, tables, entryCount];
}
