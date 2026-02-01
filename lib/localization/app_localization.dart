// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// class AppLocalizations {
//   final Locale locale;
//   late Map<String, String> _localizedStrings;
//
//   AppLocalizations(this.locale);
//
//   static AppLocalizations? of(BuildContext context) {
//     return Localizations.of<AppLocalizations>(context, AppLocalizations);
//   }
//
//   Future<void> load() async {
//     final jsonString =
//     await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
//     final Map<String, dynamic> jsonMap = json.decode(jsonString);
//
//     _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
//   }
//
//   String translate(String key, {Map<String, String>? params}) {
//     String text = _localizedStrings[key] ?? key;
//     if (params != null) {
//       params.forEach((k, v) => text = text.replaceAll('{$k}', v));
//     }
//     return text;
//   }
//
//   static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
// }
//
// class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
//   const _AppLocalizationsDelegate();
//
//   @override
//   bool isSupported(Locale locale) => ['en', 'mr'].contains(locale.languageCode);
//
//   @override
//   Future<AppLocalizations> load(Locale locale) async {
//     final localizations = AppLocalizations(locale);
//     await localizations.load();
//     return localizations;
//   }
//
//   @override
//   bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
// }
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mpcb_bio_waste/Localization/localization_delegate.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  // ✅ Returns non-nullable by asserting delegate is loaded
  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (instance == null) {
      throw Exception(
          "AppLocalizations not found in context. Make sure AppLocalizations.delegate is added in MaterialApp.localizationsDelegates");
    }
    return instance;
  }

  Future<void> load() async {
    final jsonString =
    await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  String translate(String key, {Map<String, String>? params}) {
    String text = _localizedStrings[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();
}
