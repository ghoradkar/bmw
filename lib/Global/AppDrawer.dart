import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/CBWTF/apiservice.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/filter.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/view_details_after_Scan.dart';
import 'package:mpcb_bio_waste/Global/size_config.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CBWTF_Disposal/disposal_overall_colection.dart';
import '../HCF/filter.dart';
import '../authentication/logout.dart';
import 'app_routes.dart';

class AppDrawer extends StatefulWidget {


  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String username = '';
  String email = '';
  String? userRole ;
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  void _redirectToRoleScreen(String? role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    user=await jsonDecode(prefs.getString('user')!);
    print('user');
    if (userRole == 'Disposal User') {
      if ( user!['bulkDataSaveFlag']=='N') {
        Navigator.of(context).popAndPushNamed(AppRoutes.waste_received_byvehicle);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisposalOverallCollection(),
          ),
        );
      }
      return;
    }

    final routeMap = {
      'HCF User': AppRoutes.hcf_biowasteScreen,
      'CBWT User': AppRoutes.nearby_hcf,
      //  'CBWT User': AppRoutes.nearby_hcf,
      'CBWT Reception User': AppRoutes.vehicle_screen,
      //'Disposal User': AppRoutes.waste_received_byvehicle,
      'Vehicle  User': AppRoutes.vehicle_nearby_hcf,
    };

    final route = routeMap[role];
    if (route != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } else {
      _showError('Unknown User !!');
    }
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('userRole') ?? 'Guest';
      userRole= prefs.getString('userRole');
      //email = prefs.getString('UserEmail') ?? 'guest@example.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Drawer(

      child: Container(
        
        decoration:  BoxDecoration( gradient: LinearGradient(
            colors: [
              Color.fromRGBO(75, 197, 217, 1),
              Color.fromRGBO(21, 144, 207, 1)
            ],
            begin: FractionalOffset(1.0, 0.0),
            end: FractionalOffset(1.0, 1.0),
            stops: [0.0, 1.0],
            tileMode: TileMode.clamp),),
        child:Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsiveHeight(100),),

      Center(
        child: Container(
          height: 50,
          width: 50,
          child: Icon(
            Icons.person,
            color: Colors.black54,
          ),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                  Radius.circular(10)),
              border: Border.all(
                  color: Colors.white),
              color: Colors.grey.shade400),
        ),
      ),
              SizedBox(height: responsiveHeight(30),),

      Center(
          child: Text(
            username == null ? '' : username!,
            style: TextStyle(color: Colors.white,fontSize: 14),
          )),
      SizedBox(
        height: 40,
      ),
      SizedBox(
        height:
        400,
        child: ListView(
          scrollDirection: Axis.vertical,
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
           ListTile(
              leading: Icon(
                Icons.dashboard,
                color: Colors.white,
              ),
              title: Text(
                  'Dashboard',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                _redirectToRoleScreen(userRole);
                // Update the state of the app.
                // ...
              },
            ),
            username== 'Disposal User'? ListTile(
              leading: Icon(
                Icons.receipt_long,
                color: Colors.white,
              ),
              title: Text(
                  'Search Disposal Data',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>Filter_disposal()
                  ),
                );
                // Update the state of the app.
                // ...
              },
            ):SizedBox(),
           username== 'HCF User'? ListTile(
              leading: Icon(
                Icons.receipt_long,
                color: Colors.white,
              ),
              title: Text(
                  'Search HCF Data',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>ViewDetails(),
                  ),
                );
                // Update the state of the app.
                // ...
              },
            ):SizedBox(),
        username=='CBWT Reception User'? ListTile(
          leading: Icon(
            Icons.receipt,
            color: Colors.white,
          ),
          title: Text(
              'View Details',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>ViewDetailsAfterScan(),
              ),
            );

            // Update the state of the app.
            // ...
          },
        ):SizedBox(),

      //   ListTile(
      //   leading: Icon(
      //   Icons
      //       .dashboard_customize_outlined,
      //     color: Colors.white,
      //   ),
      //   title: Text(
      //       'ID Card',
      //       style: TextStyle(
      //           color: Colors.white,
      //           fontSize: 15)),
      //   onTap: () {
      //
      //     // Update the state of the app.
      //     // ...
      //   },
      // ),
            ListTile(
              leading: Icon(
                Icons
                    .logout,
                color: Colors.white,
              ),
              title: Text(
                  'Logout',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                Navigator.of(context).pushNamed(AppRoutes.logout);

                // Update the state of the app.
                // ...
              },
            ),
            SizedBox(height: responsiveHeight(310),),
            ListTile(

              title: Text(
                  'Version $appVersion',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {


                // Update the state of the app.
                // ...
              },
            ),
    ]),
    )])));
  }
}
