import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

import '../splash_screen.dart';
import 'update.dart';

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  Future<bool> _shouldForceUpdate() async {
    final newVersion = NewVersionPlus(
      androidId: 'com.bmw.app',
      iOSId: '6747034838',
    );

    try {
      final status = await newVersion.getVersionStatus();
      return status?.canUpdate ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldForceUpdate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ✅ NO Scaffold here
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data == true) {
          return  Update(); // screen with Scaffold inside
        }

        return  SplashScreen(); // screen with Scaffold inside
      },
    );
  }
}
