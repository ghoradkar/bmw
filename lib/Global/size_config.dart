import 'package:flutter/material.dart';

class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double screenWidth = 1080.0;
  static double screenHeight = 720.0;

  static double designScreenWidth = 428.0;
  static double designScreenHeight = 926.0;
  static double scaleFactor = 0;
  static double widthScaleFactor = 0;
  static double heightScaleFactor = 0;

  static double? defaultSize;
  static Orientation? orientation;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    orientation = _mediaQueryData!.orientation;
    widthScaleFactor = screenWidth / designScreenWidth;
    heightScaleFactor = screenHeight / designScreenHeight;
    scaleFactor = screenWidth / designScreenWidth;
  }

  double getBottomPadding() {
    final bottomPadding = _mediaQueryData!.padding.bottom;
    return bottomPadding;
  }
}

double responsiveFont(double fontSize) {
  return fontSize * SizeConfig.scaleFactor;
}

double responsiveWidth(double width) {
  return width * SizeConfig.widthScaleFactor;
}

double responsiveHeight(double height) {
  return height * SizeConfig.heightScaleFactor;
}

// Get the proportionate height as per screen size
double getProportionateScreenHeight(double inputHeight) {
  double screenHeight = SizeConfig.screenHeight;
  // 812 is the layout height that designer use
  return (inputHeight / screenHeight) * screenHeight;
}

// Get the proportionate height as per screen size
double getProportionateScreenWidth(double inputWidth) {
  double screenWidth = SizeConfig.screenWidth;
  // 375 is the layout width that designer use
  return (inputWidth / screenWidth) * screenWidth;
}

// Get the proportionate height as per screen size
double getProportionateScreenHeightNew(
    double inputHeight, double? inputScreenHeight) {
  // double screenHeight = SizeConfig.screenHeight;
  // 812 is the layout height that designer use
  double scHeight = inputScreenHeight ?? SizeConfig.screenHeight;
  return (inputHeight / scHeight) * scHeight;
}

// Get the proportionate height as per screen size
double getProportionateScreenWidthNew(
    double inputWidth, double? inputScreenWidth) {
  // double screenWidth = SizeConfig.screenWidth;
  // 375 is the layout width that designer use
  double scHeight = inputScreenWidth ?? SizeConfig.screenHeight;
  return (inputWidth / scHeight) * scHeight;
}
