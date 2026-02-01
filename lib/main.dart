import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


import 'package:mpcb_bio_waste/splash_screen.dart';
import 'package:provider/provider.dart';

import 'Global/app_routes.dart';
import 'Global/app_theme.dart';
import 'Global/appentrypoint.dart';
import 'Global/navigator_observer.dart';
import 'Global/size_config.dart';

import 'localization/app_localization.dart' show AppLocalizations;
import 'localization/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(  ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MyApp()));
}


// class MyApp extends StatefulWidget {
//   static void setLocale(BuildContext context, Locale newLocale) {
//     _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
//     state?.setLocale(newLocale);
//   }
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   Locale _locale = const Locale('mr');
//
//   void setLocale(Locale locale) {
//     setState(() {
//       _locale = locale;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       locale: _locale,
//       supportedLocales: const [Locale('en'), Locale('mr')],
//       localizationsDelegates: const [
//         AppLocalizationDelegate(),
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       title: 'MPCB Bio Waste',
//       debugShowCheckedModeBanner: false,
//       navigatorObservers: [MyNavigatorObserver()],
//       onGenerateRoute: AppRoutes.onGenerateRoute,
//       theme: AppTheme.lightTheme,
//       home: SplashScreen(),
//     );
//   }
// }
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final _MyAppState? state =
    context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: langProvider.locale,
      supportedLocales: const [Locale('en'), Locale('mr')],
      localizationsDelegates: const [
        AppLocalizations.delegate, // ✅ your delegate here
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],


      title: 'MPCB Bio Waste',
     // debugShowCheckedModeBanner: false,
      navigatorObservers: [MyNavigatorObserver()],
      onGenerateRoute: AppRoutes.onGenerateRoute,
      theme: AppTheme.lightTheme,


      home: const AppEntryPoint(), // 👈 IMPORTANT
    );
  }
}

