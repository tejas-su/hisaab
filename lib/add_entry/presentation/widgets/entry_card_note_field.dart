import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';

/// The entry card's note, typed in place (SPEC FR-AD-8 AC-7): at most 80 characters, with a count
/// while focused. The keyboard's done key keeps it; so does moving on (AC-8).
class EntryCardNoteField extends StatefulWidget {
  const EntryCardNoteField({super.key, required this.note, required this.onChanged});

  /// The note as the card holds it; the field starts from it.
  final String note;
  final ValueChanged<String> onChanged;

  @override
  State<EntryCardNoteField> createState() => _EntryCardNoteFieldState();
}

class _EntryCardNoteFieldState extends State<EntryCardNoteField> {
  late final TextEditingController _controller = TextEditingController(text: widget.note);
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // why: the count shows only while the field is focused.
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Semantics(
      label: strings.entryCardNote,
      child: TextField(
        key: const ValueKey<String>('entry-card-note'),
        controller: _controller,
        focusNode: _focus,
        maxLength: EntryValidator.maxNoteLength,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        onChanged: widget.onChanged,
        onSubmitted: (String _) => _focus.unfocus(),
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: strings.addNote,
          counterText: _focus.hasFocus ? null : '',
          prefixIcon: const AppIcon(AppIcons.note),
          fillColor: context.colors.background,
        ),
      ),
    );
  }
}
