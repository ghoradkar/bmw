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




  // Submit form data
  static Future<List> Get_cbwtf_data(BuildContext context,hcfcode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('Token') ?? '';
    final response = await http.get(
      Uri.parse('${baseurl}${GET_BIO_WASTE_DATA}$hcfcode'),

       headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    },
    ).timeout(const Duration(seconds: 15));
    print('${baseurl}${GET_BIO_WASTE_DATA}$hcfcode');
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