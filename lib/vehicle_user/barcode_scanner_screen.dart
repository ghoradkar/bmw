import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';
import 'after_scan_Screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Map<String, dynamic> detail;
  final List<dynamic> rows;
  final List<TextEditingController> receivedQtyControllers;
  final List<bool> valueEntered;

  const BarcodeScannerScreen(
      this.detail,
      this.rows,
      this.receivedQtyControllers,
      this.valueEntered, {
        super.key,
      });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController qrController) {
    controller = qrController;

    controller!.scannedDataStream.listen((scanData) async {
      if (isScanned) return;

      final barcode = scanData.code ?? '';
      if (barcode.isEmpty) return;

      print(barcode);
      // Prevent duplicates before returning
      final alreadyScanned =
      widget.rows.any((row) => row['barcodeNo'] == barcode);

      if (alreadyScanned) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Barcode already scanned')),
        );
        return;
      }

      isScanned = true;
      await controller!.pauseCamera();

      // Return scanned barcode to previous screen
      if (widget.rows.isEmpty){
        print(barcode);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AfterScanScreen(
              barcode: barcode,
              rows: widget.rows,
              receivedQtyControllers: widget.receivedQtyControllers,
              value_entered: widget.valueEntered,
              detail: widget.detail,

            ),
          ),
        );}
      else{
     Navigator.pop(context, barcode);
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
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    return StreamProvider<NetworkStatus>(
      create: (_) => NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              /// AppBar
              mAppBar(
                onLeadingIconClick: () => Navigator.pop(context),
                scTitle: 'Scan QR Code',
                centerTile: false,
                showLeading: true,
              ),

              /// QR Scanner Body
              Positioned.fill(
                top: responsiveHeight(110),
                bottom: responsiveHeight(0),
                child: Container(
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
                        flex: 5,
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                          overlay: QrScannerOverlayShape(
                            borderColor: Colors.green,
                            borderRadius: 10,
                            borderLength: 30,
                            borderWidth: 10,
                            cutOutSize:
                            MediaQuery.of(context).size.width * 0.8,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code),
                              label: const Text("Scan Again"),
                              onPressed: () {
                                isScanned = false;
                                controller?.resumeCamera();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                              ),
                            ),
                          ],
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

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
//
// import '../Global/app_bar.dart';
// import '../Global/constant.dart';
// import '../Global/size_config.dart';
// import '../network/network_aware.dart';
// import '../network/network_status.dart';
// import '../network/offline.dart';
// import 'package:mpcb_bio_waste/vehicle_user/after_scan_Screen.dart';
//
// class BarcodeScannerScreen extends StatefulWidget {
//   final Map<String, dynamic> detail;
//  final  List<dynamic> rows;
//  final List<TextEditingController>_receivedQtyControllers;
//  final List<bool>value_entered;
//
//   const BarcodeScannerScreen(this.detail, this.rows,this._receivedQtyControllers,this.value_entered,{super.key});
//
//   @override
//   State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
// }
//
// class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   bool isScanned = false;
//
//
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (Platform.isAndroid) {
//       controller?.pauseCamera();
//     }
//     controller?.resumeCamera();
//   }
//
//
//   // void _onQRViewCreated(QRViewController qrController) {
//   //   controller = qrController;
//   //   controller?.scannedDataStream.listen((scanData) {
//   //     if (!isScanned) {
//   //       isScanned = true;
//   //       controller?.pauseCamera();
//   //
//   //       final scannedCode = scanData.code ?? '';
//   //
//   //       // Make sure rows is initialized
//   //
//   //
//   //       // ✅ Check if this barcode already exists in rows
//   //       // final alreadyExists = widget.rows.any((row) => row['barcode'] == scannedCode);
//   //       //
//   //       // if (!alreadyExists) {
//   //       //   widget.rows.add({
//   //       //     'barcode': scannedCode,
//   //       //     'qtyByHCF': '', // you can set default/empty values
//   //       //     'quantityReceived': '',
//   //       //     'difference': '',
//   //       //   });
//   //       // }
//   //
//   //       Navigator.pushReplacement(
//   //         context,
//   //         MaterialPageRoute(
//   //           builder: (context) => AfterScanScreen(
//   //             barcode: scannedCode,
//   //             rows: widget.rows,
//   //             receivedQtyControllers: widget._receivedQtyControllers,
//   //             value_entered: widget.value_entered,
//   //             detail: widget.detail,
//   //
//   //           ),
//   //         ),
//   //       );
//   //     }
//   //   });
//   // }
//
//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//
//     controller.scannedDataStream.listen((scanData) async {
//       if (isScanned) return;
//
//       isScanned = true;               // 🔐 lock scanning
//       await controller.pauseCamera();
//
//       final barcode = scanData.code ?? '';
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => AfterScanScreen(
//                     barcode: barcode,
//                     rows: widget.rows,
//                     receivedQtyControllers: widget._receivedQtyControllers,
//                     value_entered: widget.value_entered,
//                     detail: widget.detail,
//
//                   ),
//         ),
//       );
//     });
//   }
//
//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//
//     return StreamProvider<NetworkStatus>(
//       create: (_) => NetworkStatusService().networkStatusController.stream,
//       initialData: NetworkStatus.Online,
//       child: NetworkAwareWidget(
//         onlineChild: Scaffold(
//           backgroundColor: Colors.white,
//           body: Stack(
//             children: [
//               /// AppBar
//               mAppBar(
//                 onLeadingIconClick: () => Navigator.pop(context),
//                 scTitle: 'Scan QR Code',
//                 centerTile: false,
//                 showLeading: true,
//               ),
//
//               /// QR Scanner Body
//               Positioned.fill(
//                 top: responsiveHeight(110),
//                 bottom: responsiveHeight(
//                   0,
//                 ), // offset to appear below custom app bar
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: kWhiteColor,
//                     borderRadius: const BorderRadius.only(
//                       topRight: Radius.circular(40),
//                       topLeft: Radius.circular(40),
//                     ),
//                   ),
//                   child:Column(children: [
//                     Expanded(
//                       flex: 5,
//                       child: QRView(
//                         key: qrKey,
//                         onQRViewCreated: _onQRViewCreated,
//                         overlay: QrScannerOverlayShape(
//                           borderColor: Colors.green,
//                           borderRadius: 10,
//                           borderLength: 30,
//                           borderWidth: 10,
//                           cutOutSize: MediaQuery.of(context).size.width * 0.8,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           ElevatedButton.icon(
//                             icon: const Icon(Icons.qr_code),
//                             label: const Text("Scan Again"),
//                             onPressed: () {
//                               isScanned = false;
//                               controller?.resumeCamera();
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.deepOrange,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//               )]),
//
//           ),
//
//         offlineChild:  Offline(),
//       ),
//     );
//   }
// }
