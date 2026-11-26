/// Spends feature: where the money went, pace, insights, every entry of a cycle, and the
/// *Can I afford it?* check with its Undo.
library;

export 'di/spends_module.dart';
export 'domain/entities/saving_started.dart';
export 'domain/entities/spends_overview.dart';
export 'domain/usecase/get_afford_inputs.dart';
export 'domain/usecase/get_month_story.dart';
export 'domain/usecase/get_spends_overview.dart';
export 'domain/usecase/is_income_set_up.dart';
export 'domain/usecase/start_saving_for.dart';
export 'domain/usecase/undo_start_saving.dart';
export 'presentation/bloc/afford_bloc.dart';
export 'presentation/bloc/afford_event.dart';
export 'presentation/bloc/afford_state.dart';
export 'presentation/bloc/afford_undo_bloc.dart';
export 'presentation/bloc/afford_undo_event.dart';
export 'presentation/bloc/afford_undo_state.dart';
export 'presentation/bloc/entries_bloc.dart';
export 'presentation/bloc/entries_event.dart';
export 'presentation/bloc/entries_state.dart';
export 'presentation/bloc/month_story_bloc.dart';
export 'presentation/bloc/month_story_event.dart';
export 'presentation/bloc/spends_bloc.dart';
export 'presentation/bloc/spends_event.dart';
export 'presentation/bloc/spends_state.dart';
export 'presentation/cycle_label.dart';
export 'presentation/pages/afford_sheet.dart';
export 'presentation/pages/entries_page.dart';
export 'presentation/pages/month_story_page.dart';
export 'presentation/pages/spends_page.dart';
export 'presentation/widgets/afford/afford_undo_listener.dart';
