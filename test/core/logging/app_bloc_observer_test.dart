import 'package:hisaab/core/logging/app_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _SwitchEvent {}

final class _SwitchFlipped extends _SwitchEvent {
  _SwitchFlipped(this.secret);

  final String secret;
}

class _SwitchBloc extends Bloc<_SwitchEvent, bool> {
  _SwitchBloc() : super(false) {
    on<_SwitchFlipped>((_SwitchFlipped event, Emitter<bool> emit) => emit(!state));
  }
}

void main() {
  test('logs each transition by event and state type, never their contents', () async {
    final List<Map<String, Object?>> logged = <Map<String, Object?>>[];
    final BlocObserver previous = Bloc.observer;
    Bloc.observer = AppBlocObserver(log: ({required String tag, Map<String, Object?> data = const <String, Object?>{}}) {
      logged.add(<String, Object?>{'tag': tag, ...data});
    });
    addTearDown(() => Bloc.observer = previous);
    final _SwitchBloc bloc = _SwitchBloc()..add(_SwitchFlipped('note text'));

    await pumpEventQueue();
    await bloc.close();

    expect(logged, <Map<String, Object?>>[
      <String, Object?>{'tag': 'bloc.transition', 'bloc': '_SwitchBloc', 'event': '_SwitchFlipped', 'from': 'bool', 'to': 'bool'},
    ]);
  });
}
