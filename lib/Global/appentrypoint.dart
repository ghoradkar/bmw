
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/Global/update.dart';
import 'package:new_version_plus/new_version_plus.dart';

import '../main.dart';
// Replace with your actual main app widget

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  Future<bool> _shouldForceUpdate() async {
    final newVersion = NewVersionPlus(
      androidId: 'com.mpcb_bio_waste.app',   // 🔁 Your actual Android package ID
      iOSId: '6747034838',                  // 🔁 Your actual iOS App Store ID
    );

    try {
      final status = await newVersion.getVersionStatus();
      if (status != null && status.canUpdate) {
        return true; // 🔒 Force update if store version is higher
      }
    } catch (e) {
      print(e);
      debugPrint('Version check failed: $e');
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldForceUpdate(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.data == true) {
          return  MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Update(),
          );
        }

        return MyApp(); // ✅ Your normal app widget
      },
    );
  }
}
