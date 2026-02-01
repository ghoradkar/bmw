import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/CBWTF/apiservice.dart';
import 'package:mpcb_bio_waste/CBWTF/search_assigned_vehicle.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/filter.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/view_details_after_Scan.dart';
import 'package:mpcb_bio_waste/Global/size_config.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/authentication/forget_password.dart';
import 'package:mpcb_bio_waste/authentication/update_password.dart';
import 'package:mpcb_bio_waste/need_help/need_help.dart';
import 'package:mpcb_bio_waste/profile/my_profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CBWTF_Disposal/disposal_overall_colection.dart';
import '../HCF/filter.dart';
import '../Localization/app_localization.dart';
import '../authentication/logout.dart';
import '../localization/provider.dart';
import '../vehicle_user/search_pickedup_Details.dart';
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
      'CBWT Assign User': AppRoutes.nearby_hcf,
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
      username = prefs.getString('username') ?? 'Guest';
      userRole= prefs.getString('userRole');
      email = prefs.getString('email') ?? 'guest@example.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

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

      GestureDetector(
          onTap:(){
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>ProfileScreen()
              ),
            );
          },
          child:Center(
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
      )),
              SizedBox(height: responsiveHeight(30),),

      Center(
          child: Text(
            username == null ? '' : username!,
            style: TextStyle(color: Colors.white,fontSize: 14),
          )),
              Center(
                  child: Text(
                    email == null ? '' : email!,
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
                  userRole== 'HCF User'?t.translate('add_waste'):userRole== 'CBWT Assign User'?t.translate('assign_vehicle'):userRole=='Vehicle  User'?t.translate('view_assigned_hcf'):userRole=='CBWT Reception User'?t.translate('list_of_vehicle'):userRole=='Disposal User'?t.translate('received_waste'):'Dashboard',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                _redirectToRoleScreen(userRole);
                // Update the state of the app.
                // ...
              },
            ),
            userRole== 'Disposal User'? ListTile(
              leading: Icon(
                Icons.receipt_long,
                color: Colors.white,
              ),
              title: Text(
                  t.translate('search_disposal_data'),
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
            userRole== 'Vehicle  User'? ListTile(
              leading: Icon(
                Icons.receipt_long,
                color: Colors.white,
              ),
              title: Text(
                  t.translate('search_pickedup_details'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>SearchPickedupDetails()
                  ),
                );
                // Update the state of the app.
                // ...
              },
            ):SizedBox(),
            userRole== 'CBWT Assign User'? ListTile(
              leading: Icon(
                Icons.person_outline,
                color: Colors.white,
              ),
              title: Text(
                  t.translate('search_assigned_vehicle'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>SearchAssignedVehicle()
                  ),
                );
                // Update the state of the app.
                // ...
              },
            ):SizedBox(),
           userRole== 'HCF User'? ListTile(
              leading: Icon(
                Icons.receipt_long,
                color: Colors.white,
              ),
              title: Text(
                  t.translate('search_generated_bmw'),
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
        userRole=='CBWT Reception User'? ListTile(
          leading: Icon(
            Icons.receipt,
            color: Colors.white,
          ),
          title: Text(
              t.translate('search_received_data'),
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
                    .lock_outline,
                color: Colors.white,
              ),
              title: Text(
                  t.translate('update_password'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>UpdatePassword(),
                  ),
                );

                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              leading: Icon(
                Icons
                    .help_outline,
                color: Colors.white,
              ),
              title: Text(
                  t.translate('need_help'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>DocumentUploadScreen(),
                  ),
                );



                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              leading: Icon(
                Icons
                    .logout,
                color: Colors.white,
              ),
              title: Text(
                  t.translate('logout'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15)),
              onTap: () {

                Navigator.of(context).pushNamed(AppRoutes.logout);

                // Update the state of the app.
                // ...
              },
            ),
            SizedBox(height: responsiveHeight(50),),
            ListTile(

              title: Text(
                  '${t.translate('version') ?? 'Version'} $appVersion',
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
