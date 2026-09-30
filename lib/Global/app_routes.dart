

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/CBWTF/get_bio_waste_data.dart';
import 'package:mpcb_bio_waste/CBWTF/nearby_hcf.dart';
import 'package:mpcb_bio_waste/CBWTF/view_detail.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_after_scan.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_scanner.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/waste_received_byvehicle.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/biowaste_received_byvehicle.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/reception_Scanner.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/vehicle_list.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/view_details_after_Scan.dart';
import 'package:mpcb_bio_waste/Global/route_exception.dart';
import 'package:mpcb_bio_waste/HCF/add_bio_waste.dart';
import 'package:mpcb_bio_waste/HCF/bio_waste_screen.dart';
import 'package:mpcb_bio_waste/authentication/forget_password.dart';
import 'package:mpcb_bio_waste/authentication/logout_screen.dart';
import 'package:mpcb_bio_waste/homeScreen.dart';
import 'package:mpcb_bio_waste/vehicle_user/after_scan_Screen.dart';
import 'package:mpcb_bio_waste/vehicle_user/assign_hcf.dart';
import 'package:mpcb_bio_waste/vehicle_user/barcode_scanner_screen.dart';
import 'package:mpcb_bio_waste/vehicle_user/bii_waste_detail.dart';
import 'package:mpcb_bio_waste/vehicle_user/nearby_hcf.dart';

import '../authentication/login_screen.dart';
import '../splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = "/";
  static const String loginScreen = "/loginScreen";
  static const String forgot_password='/forgot_password';
  static const String homescreen="/homescreen";
  static const String hcf_biowasteScreen='/hcfbiowasteScreen';
  static const String get_bio_waste='/getbiowaste';
  static const String hcf_detail_screen='/hcf_details_screen';
  static const String nearby_hcf='/nearby_hcf';
  static const String vehicle_nearby_hcf='/vehicle_nearby_hcf';
  static const String assigned_hcf='/assigned_hcf';
  static const String bio_waste_detail='/bio_waste_detail';
  static const String barcode_scanner='/barcode_scanner';
  static const String after_Scan='/after_scan_screen';
  static const String vehicle_screen='/vehicle_screen';
  static const String biowaste_received_byvehicle='/biowaste_received_byvehicle';
  static const String reception_scan='/reception_scan';
  static const String view_detail_afterscan='/view_detail_afterscan';
  static const String waste_received_byvehicle='/waste_received_byvehicle';
  static const String disposal_scan='/disposal_scan';
  static const String disposal_after_scan='/disposal_after_scan';

  static const String logout='logout';



    static Route<dynamic> onGenerateRoute(RouteSettings settings) {
      switch (settings.name) {
        case splash:
          return MaterialPageRoute(
            builder: (_) => SplashScreen(),
          );

        case loginScreen:
          return MaterialPageRoute(
            builder: (_) => LoginScreen(),
            // builder: (_) => LoginScreen('no'),
          );
        case forgot_password:
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(),
          );

        case hcf_biowasteScreen:
          return MaterialPageRoute(
            builder: (_) => AddBioWasteDataTab(),
          );
        case homescreen:
          return MaterialPageRoute(
            builder: (_) => Homescreen(),
          );
        case get_bio_waste:
          return MaterialPageRoute(
            builder: (_) => GetBioWasteData([]),
          );
        case hcf_detail_screen:
          return MaterialPageRoute(
            builder: (_) => HcfDetailsScreen(0),
          );

        case nearby_hcf:
          return MaterialPageRoute(
            builder: (_) => NearbyHCFScreen(),
          );
        case vehicle_nearby_hcf:
          return MaterialPageRoute(
            builder: (_) => DiscoverNearbyHCFScreen(),
          );
        case assigned_hcf:
          return MaterialPageRoute(
            builder: (_) => AssignedHCFScreen(),
          );
        case bio_waste_detail:
          return MaterialPageRoute(
              builder: (_) => BioWasteDetailScreen({}),
          );
        case barcode_scanner:
          return MaterialPageRoute(
            builder: (_) => BarcodeScannerScreen({},[],[],[]),
          );
        case after_Scan:
          return MaterialPageRoute(
            builder: (_) => AfterScanScreen(barcode: '',rows:[],receivedQtyControllers:[],value_entered:[],detail: {},),
          );
        case vehicle_screen:
          return MaterialPageRoute(
            builder: (_) => VehicleListScreen(),
          );
        case biowaste_received_byvehicle:
          return MaterialPageRoute(
            builder: (_) => BiowasteReceivedByvehicle(''),
          );
        case reception_scan:
          return MaterialPageRoute(
            builder: (_) => ReceptionScanner([],[],[]),
          );
        case view_detail_afterscan:
          return MaterialPageRoute(
            builder: (_) => ViewDetailsAfterScan(),
          );
        case waste_received_byvehicle:
          return MaterialPageRoute(
            builder: (_) => WasteReceivedByvehicle(),
          );
        case disposal_scan:
          return MaterialPageRoute(
            builder: (_) => DisposalScanner([],[],[]),
          );
        case disposal_after_scan:
          return MaterialPageRoute(
            builder: (_) => DisposalAfterScan('',0,[],[],[]),
          );
        case logout:
          return MaterialPageRoute(
            builder: (_) => LogoutScreen(),
          );








        default:
          throw const RouteException('Route not found!');
      }

  }
}