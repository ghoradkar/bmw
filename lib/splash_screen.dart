import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:mpcb_bio_waste/self_registration/view/self_registration_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'CBWTF_Disposal/disposal_overall_colection.dart';
import 'Global/app_routes.dart';
import 'Global/images.dart';
import 'Global/url.dart';
import 'authentication/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print(baseurl);
    // Navigate safely after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeAndNavigate();
    });
  }

  /// Blocks until the user updates, on both platforms, using each store's
  /// own official update-status API (Play In-App Updates / iTunes Lookup) —
  /// never a scraped Play Store web page, which is unreliable.
  Future<void> _forceUpdateIfAvailable() async {
    try {
      if (Platform.isAndroid) {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable &&
            info.immediateUpdateAllowed) {
          // Hands off to Play's own full-screen blocking update UI.
          await InAppUpdate.performImmediateUpdate();
        }
      } else if (Platform.isIOS) {
        final upgrader = Upgrader.sharedInstance;
        await upgrader.initialize();
        if (upgrader.shouldDisplayUpgrade()) {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => PopScope(
                  canPop: false,
                  child: AlertDialog(
                    title: const Text('Update Required'),
                    content: const Text(
                      'A new version of this app is available. Please update to continue.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => upgrader.sendUserToAppStore(),
                        child: const Text('Update Now'),
                      ),
                    ],
                  ),
                ),
          );
        }
      }
    } catch (_) {
      // Store/update-service unavailable (e.g. not installed via Play,
      // no network, no Play Services) — never block app startup on this.
    }
  }

  Future<void> _checkFirstTimeAndNavigate() async {
    await _forceUpdateIfAvailable();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('userRole');

    final userString = prefs.getString('user');
    Map<String, dynamic>? user;

    if (userString != null && userString.isNotEmpty) {
      user = jsonDecode(userString) as Map<String, dynamic>;
    }

    print('user: $user');

    // 0️⃣ Self-registered (temp survey HCF) user still awaiting scrutiny /
    // real-role assignment -> show the pending-approval screen.
    const knownRoles = {
      'HCF User',
      'CBWT Assign User',
      'CBWT Reception User',
      'Vehicle  User',
      'Disposal User',
    };
    final bool isTempSurveyUser =
        user != null && user['tempSurveyHcfUser'] == 'Y';
    if (isLoggedIn && isTempSurveyUser && !knownRoles.contains(userRole)) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelfRegistrationStatusScreen()),
      );
      return;
    }

    // 1️⃣ Disposal User special case
    if (isLoggedIn && userRole == 'Disposal User') {
      if (user != null && user['bulkDataSaveFlag'] == 'N') {
        if (!mounted) return;
        Navigator.of(context).popAndPushNamed(AppRoutes.waste_received_byvehicle);
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DisposalOverallCollection()),
        );
      }
      return;
    }

    // 2️⃣ Map roles to routes
    final roleRoutes = {
      'HCF User': AppRoutes.hcf_biowasteScreen,
      'CBWT Assign User': AppRoutes.nearby_hcf,
      'CBWT Reception User': AppRoutes.vehicle_screen,
      'Vehicle  User': AppRoutes.vehicle_nearby_hcf,
    };

    // 3️⃣ Navigate for logged-in users
    if (isLoggedIn && userRole != null && roleRoutes.containsKey(userRole)) {
      if (!mounted) return;
      Navigator.of(context).popAndPushNamed(roleRoutes[userRole]!);
      return;
    }

    // 4️⃣ Default: navigate to login after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).popAndPushNamed(AppRoutes.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              background,
              fit: BoxFit.cover,
            ),
          ),

          // Overlay with logo and text
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(secondLog, width: 100),
                      Image.asset(logo, width: 126),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'MPCB-BMW Management',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'CBWTF_Disposal/disposal_overall_colection.dart';
// import 'Global/app_routes.dart';
// import 'Global/images.dart';
// import 'authentication/login_screen.dart';
//
// class SplashScreen extends StatefulWidget {
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   bool? Login;
//   bool isFirstTimeUser = true;
//   Map<String, dynamic> decode = {};
//   Map<String, dynamic>? user;
//   String? userdecode;
//   String? current;
//   void isFirstTime() async {
//     final prefs = await SharedPreferences.getInstance();
//     final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//     final userRole = prefs.getString('userRole');
//
//     final userString = prefs.getString('user');
//     Map<String, dynamic>? user;
//
//     if (userString != null && userString.isNotEmpty) {
//       user = jsonDecode(userString) as Map<String, dynamic>;
//     }
//
//     print('user: $user');
//
//     if (userRole == 'Disposal User') {
//       if (user != null && user['bulkDataSaveFlag'] == 'N') {
//         Navigator.of(context).popAndPushNamed(AppRoutes.waste_received_byvehicle);
//       } else {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => DisposalOverallCollection(),
//           ),
//         );
//       }
//       return;
//     }
//
//     // Map roles to routes
//     final roleRoutes = {
//       'HCF User': AppRoutes.hcf_biowasteScreen,
//       'CBWT Assign User': AppRoutes.nearby_hcf,
//       'CBWT Reception User': AppRoutes.vehicle_screen,
//       'Vehicle  User': AppRoutes.vehicle_nearby_hcf,
//     };
//
//     if (isLoggedIn && userRole != null && roleRoutes.containsKey(userRole)) {
//       if (context.mounted) {
//         Navigator.of(context).popAndPushNamed(roleRoutes[userRole]!);
//       }
//     } else {
//       Future.delayed(const Duration(seconds: 2), () {
//         if (context.mounted) {
//           Navigator.of(context).popAndPushNamed(AppRoutes.loginScreen);
//         }
//       });
//     }
//   }
//
//
//   @override
//   void initState() {
//     super.initState();
//     isFirstTime();
//
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background image
//           SizedBox.expand(
//             child: Image.asset(
//               background,
//               fit: BoxFit.cover,
//             ),
//           ),
//
//           // Overlay with logo and text
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               //margin: const EdgeInsets.only(bottom: 40),
//               padding: EdgeInsets.only(left: 80,right: 80,top: 40,bottom: 40),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(topLeft: Radius.circular(15),
//                 topRight:Radius.circular(15) ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Image.asset(
//                     logo,
//                     width: 90,
//                     height:90,
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Bio Waste App',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
