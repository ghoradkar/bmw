import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/Localization/app_localization.dart' hide AppLocalizations;
import 'app_localization.dart';


class AppLocalizationDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localization = AppLocalizations(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
