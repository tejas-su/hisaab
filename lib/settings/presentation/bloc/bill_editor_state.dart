import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../ledger/ledger.dart';

/// Which question the bill editor is asking.
enum BillEditorStage {
  name,
  amount,

  /// Days 1–31; tapping one saves.
  day,
}

/// The bill editor's situation.
sealed class BillEditorState extends Equatable {
  const BillEditorState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Answering the three questions. [kind] is the chip the name came from, if any; [rejections]
/// counts refused key presses so the amount can shake; [saving] blocks a second save and
/// [saveFailed] shows "Couldn't save. Try again." [yearlyPill] is true while the name came from
/// the Insurance, School fees or Festival pill, so the amount question explains the twelfth
/// (AC-Y2); typing a name by hand never sets it.
final class BillEditorInProgress extends BillEditorState {
  const BillEditorInProgress({
    this.stage = BillEditorStage.name,
    this.label = '',
    this.kind = const Option<BillKind>.none(),
    this.rupees = 0,
    this.rejections = 0,
    this.saving = false,
    this.saveFailed = false,
    this.yearlyPill = false,
  });

  final BillEditorStage stage;
  final String label;
  final Option<BillKind> kind;
  final int rupees;
  final int rejections;
  final bool saving;
  final bool saveFailed;
  final bool yearlyPill;

  /// Returns a copy with the given fields replaced; [saving] and [saveFailed] reset unless passed.
  BillEditorInProgress copyWith({
    BillEditorStage? stage,
    String? label,
    Option<BillKind>? kind,
    int? rupees,
    int? rejections,
    bool saving = false,
    bool saveFailed = false,
    bool? yearlyPill,
  }) =>
      BillEditorInProgress(
        stage: stage ?? this.stage,
        label: label ?? this.label,
        kind: kind ?? this.kind,
        rupees: rupees ?? this.rupees,
        rejections: rejections ?? this.rejections,
        saving: saving,
        saveFailed: saveFailed,
        yearlyPill: yearlyPill ?? this.yearlyPill,
      );

  @override
  List<Object?> get props => <Object?>[stage, label, kind, rupees, rejections, saving, saveFailed, yearlyPill];
}

/// The bill is saved; the page closes.
final class BillEditorSaved extends BillEditorState {
  const BillEditorSaved();
}
