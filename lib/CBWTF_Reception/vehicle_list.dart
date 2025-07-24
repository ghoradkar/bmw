import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';
import 'biowaste_received_byvehicle.dart';

class VehicleListScreen extends StatefulWidget {
  @override
  _VehicleListScreenState createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  bool _isLoading=true;
   List<dynamic> vehicleNumbers = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetchVehicleList();
  }
  Future<void> fetchVehicleList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final username = prefs.getString('Username');
     final UserId = prefs.getString('UserId');

      final response = await http.get(
        Uri.parse('${baseurl}${GET_VEHICLE_LIST}$UserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },);
      print('${baseurl}${GET_VEHICLE_LIST}$UserId');
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String,dynamic> value = jsonDecode(response.body);


        setState(() {
         vehicleNumbers=value['data'];
          _isLoading = false;
        });
      } else {
        // handle error
        setState(() => _isLoading = false);
      }
    }
    catch (e) {
      print('Error fetching Vehicles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching Vehicles: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return StreamProvider<NetworkStatus>(
      create: (context) =>
      NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
      onlineChild:Scaffold(
      key: _scaffoldKey,

      drawer: AppDrawer(),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Custom Gradient AppBar
          mAppBar(
            onLeadingIconClick: () => Navigator.pop(context),
            scTitle: 'Vehicle List',
            centerTile: true,
            leadingWidget: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            showLeading: true,
          ),

          /// Body with tabs
          Positioned.fill(
            top: responsiveHeight(110),
            bottom: responsiveHeight(
              0,
            ), // offset to appear below custom app bar
            child: Container(
              height: responsiveHeight(100),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                color: kWhiteColor,

                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              child: _isLoading?Center(child: CircularProgressIndicator(color: kPrimaryColor,),):
              vehicleNumbers.isEmpty||vehicleNumbers==null?Datanotfound():ListView.separated(
                itemCount: vehicleNumbers.length,
                separatorBuilder: (_, __) => SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF0FBFF),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Vehicle Number : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: vehicleNumbers[index]['vehicleNo'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BiowasteReceivedByvehicle(vehicleNumbers[index]['vehicleNo']),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.remove_red_eye,
                            color: kPrimaryColor,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ), offlineChild: Offline()));
  }
}
