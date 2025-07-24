import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';

class BarcodeImageScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const BarcodeImageScreen({super.key, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
        body: Stack(
          children: [
          /// Custom Gradient AppBar
          mAppBar(
          scTitle: 'Generated Barcode',
          centerTile: true,
          showLeading:true,
          onLeadingIconClick:()=> Navigator.pop(context),
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
    child:  Center(
        child: Image.memory(imageBytes),
      ),
    ))]));
  }
}
