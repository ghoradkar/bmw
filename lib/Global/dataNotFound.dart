import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../global/constant.dart';

class Datanotfound extends StatefulWidget {
  @override
  DatanotfoundState createState() => DatanotfoundState();
}

class DatanotfoundState extends State<Datanotfound> {
  @override
  void initState() {
    super.initState();
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
                scTitle:'Data Not Found',
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
                     dataNotFound,
                        fit: BoxFit.contain,
                        width: responsiveWidth(500),
                        height: responsiveHeight(500),
                      ),
                      SizedBox(height: responsiveHeight(40)),

                      /// Retry Button
                      SizedBox(
                        width: responsiveWidth(200),
                        child: AppButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 15,
                          ),
                          text: 'Go Back',
                          onPressed: (){},
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
