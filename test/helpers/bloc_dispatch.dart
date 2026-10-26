import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets a unit test add an event and wait for its handler, in place of `bloc_test`.
extension BlocDispatch<E, S> on Bloc<E, S> {
  /// Adds [event], then waits until the handler and its awaited fakes have finished.
  Future<void> dispatch(E event) async {
    add(event);
    await pumpEventQueue();
  }
}

/// Lets a widget test drive blocs built outside its fake async zone: in `setUp`, or with
/// [buildBloc]. A bloc handles events in the zone it was built in, and one built inside the
/// fake zone never finishes `close` in a tear-down.
extension SettleBlocs on WidgetTester {
  /// Builds a bloc with [create] outside the fake async zone.
  Future<B> buildBloc<B extends BlocBase<Object?>>(B Function() create) async {
    late B bloc;
    await runAsync(() async => bloc = create());
    return bloc;
  }

  /// Settles the frames (so animation callbacks add their events), gives those blocs a real
  /// event-loop turn to handle what was added, then settles the frames they changed.
  Future<void> settle() async {
    await pumpAndSettle();
    await runAsync(() => Future<void>.delayed(Duration.zero));
    await pumpAndSettle();
  }
}
