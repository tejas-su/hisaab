import 'package:flutter/material.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../ledger/ledger.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The *Add a note* chip, which turns into a one-line field when tapped (BR-10: up to 80
/// characters). Showing the field is this widget's own leaf state.
class NoteChip extends StatefulWidget {
  const NoteChip({super.key, required this.note, required this.onChanged});

  final String note;
  final ValueChanged<String> onChanged;

  @override
  State<NoteChip> createState() => _NoteChipState();
}

class _NoteChipState extends State<NoteChip> {
  late final TextEditingController _controller = TextEditingController(text: widget.note);
  late bool _editing = widget.note.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    if (!_editing) {
      return HisaabChip(
        key: const ValueKey<String>('note-chip'),
        label: strings.addNote,
        icon: AppIcons.note,
        onPressed: () => setState(() => _editing = true),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
      child: TextField(
        key: const ValueKey<String>('note-field'),
        controller: _controller,
        autofocus: widget.note.isEmpty,
        maxLength: EntryValidator.maxNoteLength,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        onChanged: widget.onChanged,
        onTapOutside: (PointerDownEvent _) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: strings.noteHint,
          labelText: strings.addNote,
          counterText: '',
          isDense: true,
        ),
      ),
    );
  }
}
