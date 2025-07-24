import 'package:flutter/material.dart';

const kPrimaryColor = Color.fromRGBO(75, 197, 217, 1);
const kPrimaryDarkColor = Color.fromRGBO(21, 144, 207, 1);
Color kPrimaryLightColor = kPrimaryColor.withOpacity(0.5);
Color kLight=Color.fromRGBO(216, 244, 255, 1);
Color kLightBlue=Color.fromRGBO(186, 225, 255, 1);
Color kLightGreen=Color.fromRGBO(200, 235, 208, 1);
Color kLightRed=Color.fromRGBO(255, 208, 213, 1);
Color kLightYellow=Color.fromRGBO(255, 233, 172, 1);
Color kLightPurple=Color.fromRGBO(207, 215, 254, 1);
Color kLightSeaGreen=Color.fromRGBO(173, 245, 245, 1);
Color kLightViolet=Color.fromRGBO(239, 206, 255, 1);
Color kFilterBlue=Color.fromRGBO(18, 94, 126, 1);
const kPrimaryGradientColor = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF27A9E3), Color(0xFF07B259)],
);
LinearGradient kGradientHomeMenu = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF27A9E3).withOpacity(0.1),
    Color(0xFF07B259).withOpacity(0.1)
  ],
);
const kScaffoldColor = Color(0xFFFFFFFF);
const kSecondaryColor = Color(0xFF979797);
const kSecondaryVarientColor = Color(0xFFFFFFFF);
const kTextOutlineColor = Color(0xFFC7C4C4);
const kTextColor = Color(0xFF484848);
const kListTitleTextColor = Color(0xFF3D3D3D);
const kTextBlackColor = Color(0xFF000000);
const kBlackColor = Color(0xFF000000);
const kTextOpacityColor = Color(0xB3E4E4E4);
const kTextDarkBlueColor = Color(0xFF2C3F6E);
const kWhiteColor = Color(0xFFFFFFFF);
const offWhite = Color(0xFFB1B1B1);
const kHintColor = Color(0xFF2856FB);
//profile
const kActiveBtnColor = Color(0xFF700033);
const kInActiveBtnColor = Color(0xFF970045);
const kActiveBtnBorderColor = Color(0xFFED006C);
const googleButtonColor = Color(0xFFDF4B38);
const appleButtonColor = Color(0xFF232323);
const segmentButtonBorderColor = Color(0xFFB1B1B1);
const kAnimationDuration = Duration(milliseconds: 200);
const kWhatsappColor = Color(0xFF25D366);
const kTelegramColor = Color(0xFF0088cc);
const kFBColor = Color(0xFF1877F2);
const kInstaColor = Color(0xFFcd486b);
const kTextFieldBorder = Color(0xFFE1E1E1);
const kRegistrationBgColor = Color(0xFFF8F8F8);
const kLabelTextColor = Color(0xFF515151);

// final headingStyle = TextStyle(
//   fontSize: getProportionateScreenWidth(28),
//   fontWeight: FontWeight.bold,
//   color: Colors.black,
//   height: 1.5,
// );

const defaultDuration = Duration(milliseconds: 250);

// Form Error
final RegExp emailValidatorRegExp =
RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

const String kEmailNullError = "Please Enter your email";
const String kInvalidEmailError = "Please Enter Valid Email";
const String kPassNullError = "Please Enter your password";
const String kShortPassError = "Password is too short";
const String kMatchPassError = "Passwords don't match";
const String kNamelNullError = "Please Enter your name";
const String kPhoneNumberNullError = "Please Enter your phone number";
const String kAddressNullError = "Please Enter your address";

/* Server Config */

/// API's */
const String kGoogleMapAutocomplete =
    "https://maps.googleapis.com/maps/api/place/autocomplete/json";
