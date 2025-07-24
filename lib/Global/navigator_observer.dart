import 'package:flutter/material.dart';

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      print('Returned to ${previousRoute.settings.name}');
      // Perform actions here if needed
    }
  }
}
