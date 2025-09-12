import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_after_scan.dart';
import 'package:provider/provider.dart';

import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class DisposalScanner extends StatefulWidget {
  final  List<dynamic> rows;
  final List<TextEditingController>_receivedQtyControllers;
  final List<bool>value_entered;
  DisposalScanner(this.rows,this._receivedQtyControllers,this.value_entered,{super.key});
  @override
  _DisposalScannerState createState() => _DisposalScannerState();
}

class _DisposalScannerState extends State<DisposalScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedCode;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController qrController) {
    this.controller = qrController;
    qrController.scannedDataStream.listen((scanData) {
      if (scannedCode == null) {
        setState(() => scannedCode = scanData.code);
        controller?.pauseCamera();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DisposalAfterScan(scanData.code ?? '', 0,widget.rows,widget._receivedQtyControllers,widget.value_entered),
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
              /// Custom AppBar
              mAppBar(
                onLeadingIconClick: () => Navigator.pop(context),
                scTitle: 'Scan',
                centerTile: false,
                showLeading: true,
              ),

              /// QR Scanner + result
              Positioned.fill(
                top: responsiveHeight(110),
                bottom: responsiveHeight(0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 30),
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
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                          overlay: QrScannerOverlayShape(
                            borderColor: Colors.deepOrange,
                            borderRadius: 10,
                            borderLength: 30,
                            borderWidth: 8,
                            cutOutSize: 250,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          scannedCode = null;
                          controller?.resumeCamera();
                        },
                        icon: Icon(Icons.qr_code_scanner),
                        label: Text("Scan Again"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                      ),
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
