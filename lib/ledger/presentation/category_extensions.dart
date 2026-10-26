import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/category.dart';

/// Display helpers for [Category].
extension CategoryExtensions on Category {
  /// The user's rename, or the localised seed name.
  String labelIn(AppLocalizations strings) => customName ?? strings.categoryName(key);
}
