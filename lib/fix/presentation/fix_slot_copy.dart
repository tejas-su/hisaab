import 'package:equatable/equatable.dart';

import '../../core/money/money.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ledger/ledger.dart';
import 'bloc/fix_state.dart';

/// What the preview slot says for one [FixReady], as plain text (SPEC FR-FX-3, copy deck 41 §3).
final class FixSlotLines extends Equatable {
  const FixSlotLines({required this.stateClass, this.line1, this.line2, this.live = ''});

  /// Names the kind of text shown; a change crossfades and is spoken at once.
  final Object stateClass;

  /// The first line, or the helper or notice on its own; none when the slot says nothing there.
  final String? line1;

  /// The second line: the gap and its effect, or the guard's question.
  final String? line2;

  /// The short text a screen reader speaks; empty for a helper, a notice and the idle slot.
  final String live;

  /// Both lines as one sentence, for the slot's focusable text.
  String get sentence => <String?>[line1, line2].whereType<String>().join(' ');

  @override
  List<Object?> get props => <Object?>[stateClass, line1, line2, live];
}

/// The slot's two states that are not a comparison.
enum FixSlotIdle {
  /// The helper before the first digit.
  helper,

  /// "Count only this month's money." after the guard's No.
  countOnly,
}

/// Builds the slot's text for a [FixReady]. [amount] writes a sum: the display form (`₹4,200`) or
/// the spoken form (`4,200 rupees`), so the same templates serve the eye and the ear (X28).
abstract final class FixSlotCopy {
  /// The lines for [ready] in a cycle of [period] (`week` or `month`).
  static FixSlotLines of(AppLocalizations strings, FixReady ready, {required String period, required String Function(Money) amount}) {
    final FixPreview preview = ready.preview;
    if (ready.typed.isNone()) {
      return _idle(strings, ready, period);
    }
    final bool guarded = ready.guard.isSome();
    final String line2 = _line2(strings, preview, period: period, amount: amount, guarded: guarded);
    return FixSlotLines(
      stateClass: guarded ? 'guard' : preview.runtimeType,
      line1: _line1(strings, ready, preview, amount),
      line2: line2,
      live: ready.notice == FixNotice.changed ? strings.fixNoticeChanged : _live(strings, preview, line2, amount, guarded: guarded),
    );
  }

  static FixSlotLines _idle(AppLocalizations strings, FixReady ready, String period) => ready.notice == FixNotice.countOnly
      ? FixSlotLines(stateClass: FixSlotIdle.countOnly, line1: strings.fixNoticeCountOnly(period))
      : FixSlotLines(stateClass: FixSlotIdle.helper, line1: strings.fixHelper(period));

  static String _line1(AppLocalizations strings, FixReady ready, FixPreview preview, String Function(Money) amount) =>
      switch (ready.notice) {
        FixNotice.changed => strings.fixNoticeChanged,
        FixNotice.saveFailed => strings.couldntSave,
        FixNotice.none || FixNotice.countOnly => switch (preview.heldLine) {
            HeldLine.amount => strings.fixPreviewBase(amount(preview.held)),
            HeldLine.nothing => strings.fixPreviewBaseNothing,
            HeldLine.short => strings.fixPreviewBaseShort(amount(Money.zero - preview.held)),
          },
      };

  static String _line2(
    AppLocalizations strings,
    FixPreview preview, {
    required String period,
    required String Function(Money) amount,
    required bool guarded,
  }) =>
      switch (preview) {
        FixEmpty() => '',
        FixEqual() => strings.fixPreviewEqual,
        FixClose() => strings.fixPreviewClose,
        FixLower(:final Money gap, lastDay: true) => strings.fixPreviewLessLastDay(amount(gap)),
        FixLower(:final Money gap, :final Money perDay) => strings.fixPreviewLess(amount(gap), perDay.floorMajor, amount(perDay)),
        FixShort(:final Money gap, :final Money short) => strings.fixPreviewLessShort(amount(gap), amount(short)),
        FixOverToday(:final Money gap, :final Money over) => strings.fixPreviewLessOverToday(amount(gap), amount(over)),
        FixHigher(:final Money gap, lastDay: true) => strings.fixPreviewMoreLastDay(amount(gap)),
        FixHigher(:final Money gap, :final Money perDay) => strings.fixPreviewMore(amount(gap), perDay.floorMajor, amount(perDay)),
        FixLarge(:final Money gap) =>
          guarded ? strings.fixGuardQuestion(amount(gap), period) : strings.fixPreviewBig(amount(gap)),
      };

  // why: a screen reader hears the gap and its direction once, not the whole two-line sentence on
  // every digit (D186); the full sentence stays the slot's focusable text.
  static String _live(AppLocalizations strings, FixPreview preview, String line2, String Function(Money) amount, {required bool guarded}) =>
      switch (preview) {
        FixEmpty() => '',
        FixEqual() || FixClose() => line2,
        FixLower(:final Money gap) || FixShort(:final Money gap) || FixOverToday(:final Money gap) => strings.fixLiveLess(amount(gap)),
        FixHigher(:final Money gap) => strings.fixLiveMore(amount(gap)),
        FixLarge() => line2,
      };
}
