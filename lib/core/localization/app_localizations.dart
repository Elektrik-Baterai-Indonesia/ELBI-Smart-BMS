import 'package:flutter/widgets.dart';

extension AppLocalizations on BuildContext {
  bool get usesIndonesian {
    return Localizations.localeOf(this).languageCode == 'id';
  }

  String translate(String english, String indonesian) {
    return usesIndonesian ? indonesian : english;
  }
}
