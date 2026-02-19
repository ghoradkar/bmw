// reception_scanner.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/reception_after_scan.dart';

import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class ReceptionScanner extends StatefulWidget {
  final List<dynamic> rows;
  final List<TextEditingController> _receivedQtyControllers;
  final List<bool> value_entered;

  const ReceptionScanner(
      this.rows, this._receivedQtyControllers, this.value_entered,
      {super.key});

  @override
  _ReceptionScannerState createState() => _ReceptionScannerState();
}

class _ReceptionScannerState extends State<ReceptionScanner> {
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

  // void _onQRViewCreated(QRViewController qrController) {
  //   controller = qrController;
  //
  //   controller!.scannedDataStream.listen((scanData) async {
  //     if (isScanned) return;
  //
  //     final barcode = scanData.code??"";
  //     print(barcode);
  //     if (barcode.isEmpty) return;
  //
  //     final alreadyScanned =
  //     widget.rows.any((row) => row['barcodeNo'] == barcode);
  //
  //     if (alreadyScanned) {
  //       if (!mounted) return;
  //       ScaffoldMessenger.maybeOf(context)?.showSnackBar(
  //         const SnackBar(content: Text('Barcode already scanned')),
  //       );
  //       return;
  //     }
  //
  //     isScanned = true;
  //     await controller!.pauseCamera();
  //
  //
  //
  //     if (widget.rows.isEmpty) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => ReceptionAfterScan(
  //             barcode: barcode,
  //             rows: widget.rows,
  //             receivedQtyControllers: widget._receivedQtyControllers,
  //             value_entered: widget.value_entered,
  //           ),
  //         ),
  //       );
  //     } else {
  //       Navigator.pop(context, barcode);
  //     }
  //   });
  // }
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
        Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceptionAfterScan(
                      barcode: barcode,
                      rows: widget.rows,
                      receivedQtyControllers: widget._receivedQtyControllers,
                      value_entered: widget.value_entered,
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
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();
    SizeConfig().init(context);

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
                scTitle: t.translate('scan'),
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
    );}}

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: QRView(
  //       key: qrKey,
  //       onQRViewCreated: _onQRViewCreated,
  //       overlay: QrScannerOverlayShape(
  //         borderColor: Colors.deepOrange,
  //         borderRadius: 12,
  //         borderLength: 30,
  //         borderWidth: 8,
  //         cutOutSize: 250,
  //       ),
  //     ),
  //   );
  // }



// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
// import 'package:mpcb_bio_waste/CBWTF_Reception/reception_after_scan.dart';
// import 'package:provider/provider.dart';
//
// import '../Global/app_bar.dart';
// import '../Global/constant.dart';
// import '../Global/size_config.dart';
// import '../network/network_aware.dart';
// import '../network/network_status.dart';
// import '../network/offline.dart';
//
// class ReceptionScanner extends StatefulWidget {
//   final List<dynamic> rows;
//   final List<TextEditingController> _receivedQtyControllers;
//   final List<bool> value_entered;
//
//   const ReceptionScanner(
//       this.rows,
//       this._receivedQtyControllers,
//       this.value_entered, {
//         super.key,
//       });
//
//   @override
//   _ReceptionScannerState createState() => _ReceptionScannerState();
// }
//
// class _ReceptionScannerState extends State<ReceptionScanner> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   String _scannedCode = 'Scanning...';
//   bool isNavigated = false;
//   bool isScanned = false;
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null && mounted) {
//       controller!.pauseCamera();
//       controller!.resumeCamera();
//     }
//   }
//   void _onQRViewCreated(QRViewController qrController) {
//     controller = qrController;
//
//     controller!.scannedDataStream.listen((scanData) async {
//       if (isScanned) return;
//
//       final barcode = scanData.code ?? '';
//       if (barcode.isEmpty) return;
//
//       // Prevent duplicates
//       final alreadyScanned =
//       widget.rows.any((row) => row['barcodeNo'] == barcode);
//
//       if (alreadyScanned) {
//         if (mounted) {
//           ScaffoldMessenger.maybeOf(context)?.showSnackBar(
//             const SnackBar(content: Text('Barcode already scanned')),
//           );
//         }
//         return;
//       }
//
//       isScanned = true;
//
//       // Pause camera only if widget is still mounted
//       if (mounted) {
//         try {
//           await controller!.pauseCamera();
//         } catch (e) {
//           // Safe to ignore if controller already disposed
//           print("QR controller pause failed: $e");
//         }
//       }
//
//       // Return scanned barcode safely
//       if (widget.rows.isEmpty) {
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ReceptionAfterScan(
//               barcode: barcode,
//               rows: widget.rows,
//               receivedQtyControllers: widget._receivedQtyControllers,
//               value_entered: widget.value_entered,
//             ),
//           ),
//         );
//       } else {
//         if (mounted) Navigator.pop(context, {'barcodeNo': barcode});
//       }
//     });
//   }
//
//   // void _onQRViewCreated(QRViewController ctrl) {
//   //   controller = ctrl;
//   //   ctrl.scannedDataStream.listen((scanData) async {
//   //     if (!isNavigated && scanData.code != null) {
//   //       isNavigated = true;
//   //       setState(() => _scannedCode = 'Scanned: ${scanData.code}');
//   //
//   //       // 👇 Stop camera before navigating
//   //       await controller?.pauseCamera();
//   //     //  await controller?.dispose();
//   //
//   //       if (!mounted) return;
//   //
//   //       Navigator.pushReplacement(
//   //         context,
//   //         MaterialPageRoute(
//   //           builder: (context) => ReceptionAfterScan(
//   //             barcode: scanData.code!,
//   //             rows: widget.rows,
//   //             receivedQtyControllers: widget._receivedQtyControllers,
//   //             value_entered: widget.value_entered,
//   //           ),
//   //         ),
//   //       );
//   //     }
//   //   });
//   // }
//
//   @override
//   void dispose() {
//     controller?.pauseCamera();
//     controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamProvider<NetworkStatus>(
//       create: (context) =>
//       NetworkStatusService().networkStatusController.stream,
//       initialData: NetworkStatus.Online,
//       child: NetworkAwareWidget(
//         onlineChild: Scaffold(
//           backgroundColor: Colors.white,
//           body: Stack(
//             children: [
//               /// Custom Gradient AppBar
//               mAppBar(
//                 onLeadingIconClick: () => Navigator.pop(context),
//                 scTitle: 'Scan',
//                 centerTile: false,
//                 showLeading: true,
//               ),
//
//               /// Body with QR scanner
//               Positioned.fill(
//                 top: responsiveHeight(110),
//                 bottom: responsiveHeight(0),
//                 child: Container(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
//                   decoration: BoxDecoration(
//                     color: kWhiteColor,
//                     borderRadius: const BorderRadius.only(
//                       topRight: Radius.circular(40),
//                       topLeft: Radius.circular(40),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Expanded(
//                         flex: 4,
//                         child: SizedBox(
//                           width: double.infinity,
//                           height: 300, // 👈 Fixed height prevents null context
//                           child: QRView(
//                             key: qrKey,
//                             onQRViewCreated: _onQRViewCreated,
//                             overlay: QrScannerOverlayShape(
//                               borderColor: Colors.deepOrange,
//                               borderRadius: 12,
//                               borderLength: 30,
//                               borderWidth: 8,
//                               cutOutSize: 250,
//                             ),
//                             onPermissionSet: (ctrl, p) {
//                               if (!p) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                         'Camera permission denied. Please enable it in settings.'),
//                                   ),
//                                 );
//                               }
//                             },
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Text(
//                         _scannedCode,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       ElevatedButton.icon(
//                         onPressed: () async {
//                           await controller?.resumeCamera();
//                           setState(() {
//                             _scannedCode = 'Scanning...';
//                             isNavigated = false;
//                           });
//                         },
//                         icon: const Icon(Icons.qr_code),
//                         label: const Text("Scan Again"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.deepOrange,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         offlineChild:  Offline(),
//       ),
//     );
//   }
// }
