import 'package:fpdart/fpdart.dart';

/// What a widget, tile or app-shortcut tap asks the app to open (widget spec §8).
enum LaunchAction {
  /// The Add tray at the keypad: the widget's Add key, the tile and the app shortcut.
  add,

  /// Home: anywhere else on the widget, and a long-press on the tile.
  home,

  /// The widget's *Set up* key.
  setUp;

  /// The action [uri] names (`hisaab://add`, `hisaab://home`, `hisaab://setup`); [None] for no
  /// URI, another scheme or anything else.
  static Option<LaunchAction> parse(String? uri) {
    final Uri? parsed = uri == null ? null : Uri.tryParse(uri);
    if (parsed == null || parsed.scheme != _scheme || parsed.path.isNotEmpty || parsed.hasQuery) {
      return const Option<LaunchAction>.none();
    }
    return Option<LaunchAction>.fromNullable(_byHost[parsed.host]);
  }

  static const String _scheme = 'hisaab';
  static const Map<String, LaunchAction> _byHost = <String, LaunchAction>{
    'add': LaunchAction.add,
    'home': LaunchAction.home,
    'setup': LaunchAction.setUp,
  };
}
