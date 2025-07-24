import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_after_scan.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/reception_after_scan.dart';
import 'package:mpcb_bio_waste/vehicle_user/after_scan_Screen.dart';
import 'package:provider/provider.dart';

import '../Global/app_bar.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';


class DisposalScanner extends StatefulWidget {
  @override
  _DisposalScannerState createState() => _DisposalScannerState();
}

class _DisposalScannerState extends State<DisposalScanner> {
  String _scannedCode = 'Scanning...';

  @override
  void initState() {
    super.initState();
    _scanBarcode(); // Start scanning on load
  }

  Future<void> _scanBarcode() async {
    try {
      String code = await FlutterBarcodeScanner.scanBarcode(
        '#FF6686', 'Cancel', true, ScanMode.BARCODE,
      );

      if (code != '-1') {
        setState(() => _scannedCode = 'Scanned: $code');
        print('Scanned: $code');

        // Navigate to next screen

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DisposalAfterScan( code,0),
          ),
        );
      } else {
        setState(() => _scannedCode = 'Scan canceled');
      }
    } catch (e) {
      setState(() => _scannedCode = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<NetworkStatus>(
      create: (context) =>
      NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
      onlineChild:Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
          children: [
            /// Custom Gradient AppBar
            mAppBar(
              onLeadingIconClick: () => Navigator.pop(context),
              scTitle: 'Scan',
              centerTile: false,
              showLeading: true,

            ),

            /// Body with tabs
            Positioned.fill(
              top: responsiveHeight(110),
              bottom: responsiveHeight(
                0,
              ), // offset to appear below custom app bar
              child: Container(
                height: responsiveHeight(100),
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 30),
                decoration: BoxDecoration(
                  color: kWhiteColor,

                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                ),
                child:Column(children: [

                  const SizedBox(height: 20),
                  Text(_scannedCode),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _scanBarcode,
                    icon: Icon(Icons.qr_code),
                    label: Text("Scan Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                  )
                ]),
              ),
            ),
          ]),
    ), offlineChild: Offline()));
  }
}