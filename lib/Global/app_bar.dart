import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpcb_bio_waste/Global/size_config.dart';
import 'images.dart'; // path to `appbar` image
import 'constant.dart'; // contains `kWhiteColor`, `kBlackColor`, etc.


PreferredSizeWidget mAppBar({
  String? scTitle,
  IconButton? iconbutton,
  double? elevation = 0,
  bool showActions = false,
  Function()? onLeadingIconClick,
  List<Widget>? actions,
  bool showLeading = true,
  bool centerTile = false,
  Widget? leadingWidget,
}) {
  final double appBarHeight = SizeConfig.screenHeight ; // or any suitable height

  return PreferredSize(
    preferredSize: Size.fromHeight(appBarHeight),
    child: Container(
      height: appBarHeight,
      width: SizeConfig.screenWidth,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(appbar), // your image asset
          fit: BoxFit.cover,
        ),
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: elevation,
        centerTitle: centerTile,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
        ),
        leading: showLeading
            ? leadingWidget??
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onLeadingIconClick ?? () => SystemNavigator.pop(),
            )
            : const SizedBox(),
        title: scTitle != null
            ? Text(
          scTitle,
          style: TextStyle(
            fontSize:14,
            fontWeight: FontWeight.w500,
            color: kWhiteColor,
          ),
        )
            : null,
        iconTheme: const IconThemeData(color: kWhiteColor),
        actions: showActions ? actions : null,
      ),
    ),
  );
}
