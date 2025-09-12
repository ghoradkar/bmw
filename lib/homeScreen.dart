import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/Global/app_bar.dart';

import 'Global/app_routes.dart';
import 'Global/constant.dart';
import 'Global/size_config.dart';


class Homescreen extends StatefulWidget {
  @override
  State<Homescreen> createState() => _Homescreen();
}

class _Homescreen extends State<Homescreen>{
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
   return Scaffold(

     body: Stack(
    children: [
    /// Custom Gradient AppBar
    mAppBar(
    scTitle: 'Home Screen',
    centerTile: true,
    showLeading: false,
    ),

    /// Body with tabs
    Positioned.fill(
    top: responsiveHeight(110),
    bottom: responsiveHeight(0),// offset to appear below  custom app bar
    child: Container(

    decoration: BoxDecoration(
    color: kWhiteColor,
    borderRadius: const BorderRadius.only(
    topRight: Radius.circular(40),
    topLeft: Radius.circular(40),
    ),
    ),
    child:  Column(
    children: [
    SizedBox(height: responsiveHeight(20)),

       GestureDetector(
         onTap:()=> Navigator.of(context).pushNamed(AppRoutes.hcf_biowasteScreen),
         child:Text('HCF '),),
      SizedBox(height: responsiveHeight(40)),
      GestureDetector(
        onTap:()=> Navigator.of(context).pushNamed(AppRoutes.nearby_hcf),
        child:Text('CBWTF '),),
      SizedBox(height: responsiveHeight(40)),
      GestureDetector(
        onTap:()=> Navigator.of(context).pushNamed(AppRoutes.vehicle_nearby_hcf),
        child:Text('Vehicle User'),),
      SizedBox(height: responsiveHeight(40)),
      GestureDetector(
        onTap:()=> Navigator.of(context).pushNamed(AppRoutes.vehicle_screen),
        child:Text('CBWTF Reception'),),
      SizedBox(height: responsiveHeight(40)),
      GestureDetector(
        onTap:()=> Navigator.of(context).pushNamed(AppRoutes.waste_received_byvehicle),
        child:Text('CBWTF Disposal'),)


    ])))]) );
  }

}