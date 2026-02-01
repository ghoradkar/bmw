// services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/url.dart';
import '../authentication/logout.dart';




class ApiService {

  static Future<List<Map<String, dynamic>>> buildWastePayloadList({
    required List<dynamic> inputList,
    required Map<String,dynamic> vehicle

  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('user') ?? '';
    final userid = prefs.getString('UserId') ?? '';
   // print(user);
    print(vehicle);
    return inputList.map((item) {
      final String dateStr = item['wasteQtyDate']; // e.g. "2025-08-01"
      final dateParts = dateStr.split('-');        // [2025, 08, 01]
      final formattedDate = '${dateParts[0]}/${dateParts[1]}/${dateParts[2]}'; // "01/08/2025"

      return {
        "hcfWasteId": item["hcfWasteId"],
        "wasteQntyDate":formattedDate,
        "vehicleUserId": vehicle['userId'],
        "vehicleNo": vehicle['vehicleNo'],
        "userId": userid,
        "chassisNo":vehicle['vehicleChassis'],
        "vehicleAssignDate": formattedDate
      };
    }).toList();
  }



  // Submit form data
  static Future<List> Get_cbwtf_data(BuildContext context,wasteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('Token') ?? '';
    final response = await http.get(
      Uri.parse('${baseurl}${GET_BIO_WASTE_DETAILS}$wasteId'),

       headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    },
    ).timeout(const Duration(seconds: 15));
    print('${baseurl}${GET_BIO_WASTE_DATA}$wasteId');
    print(response.body);


    if (response.statusCode != 200) {
      if (response.statusCode==401){
        final authService = AuthService();
        authService.logout(context);

      }
      throw Exception('Failed to submit form: ${response.statusCode}');

    }
    Map<String,dynamic> data=jsonDecode(response.body);


    return data['data'] ;
  }

  static Future<Map<String,dynamic>> AssignVehicle(BuildContext context,body) async {



    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('Token') ?? '';
    final response = await http.post(
      Uri.parse('${baseurl}${CBWTF_ASSIGN_VEHICLE}'),

      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body)
    ).timeout(const Duration(seconds: 15));
    print(jsonEncode(body));
    print('${baseurl}${CBWTF_ASSIGN_VEHICLE}');
    print(response.body);


    if (response.statusCode != 200) {
      if (response.statusCode==401){
        final authService = AuthService();
        authService.logout(context);

      }
      throw Exception('Failed to submit form: ${response.statusCode}');

    }
    Map<String,dynamic> data=jsonDecode(response.body);


    return data ;
  }

}