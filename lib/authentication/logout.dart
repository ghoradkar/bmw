import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Global/url.dart';
import 'login_screen.dart';
  // Where your URLs and versions are defined

class AuthService {
  String? osVersion;

  Future getOSVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    osVersion = "Unknown";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      osVersion = "${androidInfo.brand} ${androidInfo.model} Android ${androidInfo.version.release}";
      //model_name=androidInfo.model;
      // Example: "Android 13"
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      osVersion = "Apple ${iosInfo.utsname.machine} iOS ${iosInfo.systemVersion}"; // Example: "iOS 17.2"
    }


  }
   Future<void> logout(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var user = prefs.getString('Username');
      var userId = prefs.getString('UserId');

      final uri = Uri.parse('$login_baseurl$LOGOUT');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };
      final body = json.encode({
        'username': user,
        'userId': userId,
        'currLoginOutFlag': 'O',
        'appversion': appVersion,
        'osVersion': osVersion,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.body.contains('Logout Successfully')) {
        await prefs.clear();

        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) => LoginScreen('no'),
          ),
              (Route route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.body),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
