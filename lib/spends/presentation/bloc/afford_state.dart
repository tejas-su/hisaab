import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/afford_answer.dart';
import '../../domain/entities/saving_started.dart';

/// What the user has typed into *Can I afford it?* so far: the item's [name], its [price] and,
/// when they said *Yes*, what they have [have] put away (FR-SP-9 AC-2, AC-3). [price] is whole
/// rupees; [have] is money, so a prefilled saving's set-aside amount keeps its paise (D222).
final class AffordDraft extends Equatable {
  const AffordDraft({this.name = '', this.price = 0, this.saidYes = false, this.have = Money.zero, this.rejections = 0});

  final String name;
  final int price;

  /// Whether *Yes* is picked on step 2; [have] counts only then.
  final bool saidYes;
  final Money have;

  /// Keys refused at the 9-digit cap, so the amount can shake once per refusal.
  final int rejections;

  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Whether *Next* can go on: the name has a letter or digit and the price is above ₹0.
  bool get canGoOn => price > 0 && _letterOrDigit.hasMatch(name);

  /// The price as money.
  Money get priceMoney => Money.fromMajor(price);

  /// What is put away for it: [have] after *Yes*, ₹0 after *Nothing yet*.
  Money get haveMoney => saidYes ? have : Money.zero;

  AffordDraft copyWith({String? name, int? price, bool? saidYes, Money? have, int? rejections}) => AffordDraft(
        name: name ?? this.name,
        price: price ?? this.price,
        saidYes: saidYes ?? this.saidYes,
        have: have ?? this.have,
        rejections: rejections ?? this.rejections,
      );

  @override
  List<Object?> get props => <Object?>[name, price, saidYes, have, rejections];
}

/// What the *Can I afford it?* sheet shows (SPEC FR-SP-9).
sealed class AffordState extends Equatable {
  const AffordState(this.draft);

  /// What has been typed; kept across steps so Back never loses it (E165).
  final AffordDraft draft;

  @override
  List<Object?> get props => <Object?>[draft];
}

/// Step 1: the name and the price on the keypad.
final class AffordItemStep extends AffordState {
  const AffordItemStep([super.draft = const AffordDraft()]);
}

/// Step 2: "Saved anything for it already?".
final class AffordHaveStep extends AffordState {
  const AffordHaveStep(super.draft);
}

/// The answer is being worked out.
final class AffordLoading extends AffordState {
  const AffordLoading(super.draft);
}

/// The answer, with what it is worked from (FR-SP-9 AC-4, AC-5).
final class AffordAnswered extends AffordState {
  const AffordAnswered(
    super.draft, {
    required this.answer,
    required this.usual,
    required this.doneBy,
    required this.existing,
    this.waysOpen = false,
    this.saving = false,
    this.saveFailed = false,
  });

  final AffordAnswer answer;

  /// The usual day's spend the breathing space is built on; [None] without history.
  final Option<Money> usual;

  /// The date the saving would be done by when there is something to save and something spare;
  /// [None] otherwise or past 10 years (BR-23 far).
  final Option<CalendarDate> doneBy;

  /// The saving of the same name when the answer opened (D221), so an Undo restores it.
  final Option<RecurringRule> existing;

  /// Whether *Other ways* is open.
  final bool waysOpen;

  /// Whether *Start saving* is being written.
  final bool saving;

  /// Whether the last *Start saving* failed.
  final bool saveFailed;

  AffordAnswered copyWith({bool? waysOpen, bool? saving, bool? saveFailed}) => AffordAnswered(
        draft,
        answer: answer,
        usual: usual,
        doneBy: doneBy,
        existing: existing,
        waysOpen: waysOpen ?? this.waysOpen,
        saving: saving ?? this.saving,
        saveFailed: saveFailed ?? this.saveFailed,
      );

  @override
  List<Object?> get props => <Object?>[draft, answer, usual, doneBy, existing, waysOpen, saving, saveFailed];
}

/// The answer could not be read; Back returns to step 2.
final class AffordFailed extends AffordState {
  const AffordFailed(super.draft);
}

/// *Start saving* wrote [started]; the sheet closes and Spends offers Undo (AC-6).
final class AffordSavingStarted extends AffordState {
  const AffordSavingStarted(super.draft, this.started);

  final SavingStarted started;

  @override
  List<Object?> get props => <Object?>[draft, started];
}

/// Back on step 1: the sheet closes and the draft is dropped (AC-7).
final class AffordClosed extends AffordState {
  const AffordClosed(super.draft);
}
