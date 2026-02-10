import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _checkFirstTimeAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('userRole');

    final userString = prefs.getString('user');
    Map<String, dynamic>? user;

    if (userString != null && userString.isNotEmpty) {
      user = jsonDecode(userString) as Map<String, dynamic>;
    }

    print('user: $user');

    // 1️⃣ Disposal User special case
    if (userRole == 'Disposal User') {
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
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    logo,
                    width: 90,
                    height: 90,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bio Waste App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
