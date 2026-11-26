import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/home/domain/entities/reached_line.dart';
import 'package:hisaab/home/presentation/bloc/home_bloc.dart';
import 'package:hisaab/home/presentation/bloc/home_event.dart';
import 'package:hisaab/home/presentation/bloc/home_state.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

final Money _target = Money.fromMajor(12000);
final RecurringRule _insurance = WorkedExample.insurance.copyWith(target: Option<Money>.of(_target));

/// Home loads the reached line's candidate with the due-soon read (SPEC FR-HO-3, BR-23; spec §15.3).
void main() {
  late FakeServices services;
  late HomeBloc bloc;

  setUp(() {
    services = FakeServices(
      entries: <Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns],
      rules: <RecurringRule>[...WorkedExample.rules, _insurance],
    );
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<HomeReady> load({bool reachedLine = true}) async {
    bloc = services.homeBloc(getSetAside: reachedLine ? GetSetAside(recurring: services.recurring, ledger: services.ledger) : null);
    await bloc.dispatch(const HomeLoadRequested());
    return bloc.state as HomeReady;
  }

  test('a saving at its target is the pending candidate', () async {
    final HomeReady ready = await load();

    expect(ready.reachedLine, Option<ReachedLine>.of(ReachedLine(saving: _insurance, target: _target, pending: true)));
  });

  test('below its target there is no candidate', () async {
    services.recurring.rules = <RecurringRule>[...WorkedExample.rules, _insurance.copyWith(target: Option<Money>.of(Money.fromMajor(12001)))];

    final HomeReady ready = await load();

    expect(ready.reachedLine, const Option<ReachedLine>.none());
  });

  test('a failed set-aside read just leaves the line out', () async {
    final FakeLedgerRepository broken = FakeLedgerRepository()..failure = DatabaseFailure('locked');
    bloc = services.homeBloc(getSetAside: GetSetAside(recurring: services.recurring, ledger: broken));

    await bloc.dispatch(const HomeLoadRequested());

    expect(bloc.state, isA<HomeReady>().having((HomeReady r) => r.reachedLine, 'reachedLine', const Option<ReachedLine>.none()));
  });

  test('without the use case (older constructions) there is no candidate', () async {
    final HomeReady ready = await load(reachedLine: false);

    expect(ready.reachedLine, const Option<ReachedLine>.none());
  });

  test('a later copy keeps the candidate', () async {
    final HomeReady ready = await load();

    expect(ready.copyWith(showWeek: true).reachedLine, ready.reachedLine);
  });
}
