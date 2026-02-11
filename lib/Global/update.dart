import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpcb_bio_waste/Global/size_config.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global/constant.dart';

import 'app_bar.dart';
import 'app_button.dart';
import 'images.dart';

class Update extends StatefulWidget {
  // String access='';

  @override
  UpdateState createState() =>  UpdateState();}



class  UpdateState extends State<Update> {
  @override
  void initState() {
    super.initState();
  }
  // final String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.mpcb.surveyor&hl=en'; // 🔁 Replace with your app's package name

  final String androidAppId = 'com.bmw.app';
  final String iOSAppId = '6747034838'; // e.g. 'id1234567890'

  void _launchStore() async {
    Uri url;

    if (Platform.isAndroid) {
      url = Uri.parse(
          'https://play.google.com/store/apps/details?id=$androidAppId');
    } else if (Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/app/$iOSAppId');
      print(url);
    } else {
      return;
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('⚠️ Could not launch $url');
    }
  }


  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Stack(
            children: [
              /// Custom Gradient AppBar
              mAppBar(
                scTitle: 'App Update',
                centerTile: true,

                showLeading: false,

              ),

              /// Body with tabs
              Positioned.fill(
                top: responsiveHeight(110),
                bottom: responsiveHeight(0),// offset to appear below custom app bar
                child: Container(

                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                    ),
                  ),
                  child:  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Offline Image
                      Image.asset(
                        update,
                        fit: BoxFit.contain,
                        width: responsiveWidth(500),
                        height: responsiveHeight(500),
                      ),
                      SizedBox(height: responsiveHeight(40)),

                      /// Retry Button
                      SizedBox(
                        width: responsiveWidth(230),
                        child: AppButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 15,
                          ),
                          text: 'Update App',
                          onPressed: () => {_launchStore()},
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}
