import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Global/app_routes.dart';
import 'Global/images.dart';
import 'authentication/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool? Login;
  bool isFirstTimeUser = true;
  Map<String, dynamic> decode = {};
  Map<String, dynamic>? user;
  String? userdecode;
  String? current;
  void isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('userRole');

    // Map roles to routes
    final roleRoutes = {
      'HCF User': AppRoutes.hcf_biowasteScreen,
      'CBWT User': AppRoutes.nearby_hcf,
      'CBWT Reception User': AppRoutes.vehicle_screen,
      'Disposal User': AppRoutes.waste_received_byvehicle,
      'Vehicle  User': AppRoutes.vehicle_nearby_hcf,
    };

    if (isLoggedIn && userRole != null && roleRoutes.containsKey(userRole)) {
      if (context.mounted) {
        Navigator.of(context).popAndPushNamed(roleRoutes[userRole]!);
      }
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Navigator.of(context).popAndPushNamed(AppRoutes.loginScreen);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    isFirstTime();

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
              //margin: const EdgeInsets.only(bottom: 40),
              padding: EdgeInsets.only(left: 80,right: 80,top: 40,bottom: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15),
                topRight:Radius.circular(15) ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    logo,
                    width: 90,
                    height:90,
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
          )
        ],
      ),
    );
  }
}
