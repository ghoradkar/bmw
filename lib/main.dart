import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/splash_screen.dart';

import 'Global/app_routes.dart';
import 'Global/app_theme.dart';
import 'Global/appentrypoint.dart';
import 'Global/navigator_observer.dart';
import 'Global/size_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppEntryPoint());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'MPCB Bio Waste',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [MyNavigatorObserver()],
      onGenerateRoute: AppRoutes.onGenerateRoute,
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
    );
  }
}

