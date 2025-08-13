import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/reception_after_scan.dart';
import 'package:provider/provider.dart';

import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class ReceptionScanner extends StatefulWidget {
  @override
  _ReceptionScannerState createState() => _ReceptionScannerState();
}

class _ReceptionScannerState extends State<ReceptionScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String _scannedCode = 'Scanning...';
  bool isNavigated = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (mounted) {
        controller!.pauseCamera();
        controller!.resumeCamera();
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isNavigated && scanData.code != null) {
        setState(() => _scannedCode = 'Scanned: ${scanData.code}');
        isNavigated = true;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceptionAfterScan(barcode: scanData.code!),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<NetworkStatus>(
      create: (context) =>
      NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
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

              /// Body with QR scanner
              Positioned.fill(
                top: responsiveHeight(110),
                bottom: responsiveHeight(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(_scannedCode),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          controller?.resumeCamera();
                          setState(() {
                            _scannedCode = 'Scanning...';
                            isNavigated = false;
                          });
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text("Scan Again"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        offlineChild: Offline(),
      ),
    );
  }
}
