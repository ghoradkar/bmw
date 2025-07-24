import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../global/constant.dart';
import 'logout.dart';

class LogoutScreen extends StatefulWidget {
  @override
  LogoutScreenState createState() => LogoutScreenState();
}

class LogoutScreenState extends State<LogoutScreen> {
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
                scTitle: 'Log Out',
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
                        logout,
                        fit: BoxFit.contain,
                        width: responsiveWidth(500),
                        height: responsiveHeight(500),
                      ),
                      SizedBox(height: responsiveHeight(100)),

                      ///  Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: responsiveWidth(150),
                            child: AppButton(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 15,
                              ),
                              text: 'Yes',
                              onPressed: (){
                                final authService = AuthService();
                                authService.logout(context);
                              },
                              color: Colors.deepOrange,
                            ),
                          ),
                          SizedBox(
                            width: responsiveWidth(150),
                            child: AppButton(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 15,
                              ),
                              text: 'No',
                              onPressed: (){Navigator.pop(context);},
                              color: Colors.grey.shade400,
                            ),
                          ),

                        ],
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
