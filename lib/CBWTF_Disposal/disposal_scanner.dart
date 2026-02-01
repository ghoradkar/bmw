import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:provider/provider.dart';

import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_after_scan.dart';
import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class DisposalScanner extends StatefulWidget {
  final List<dynamic> rows;
  final List<TextEditingController> receivedQtyControllers;
  final List<bool> valueEntered;

  const DisposalScanner(
      this.rows,
      this.receivedQtyControllers,
      this.valueEntered, {
        super.key,
      });

  @override
  State<DisposalScanner> createState() => _DisposalScannerState();
}

class _DisposalScannerState extends State<DisposalScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  bool isProcessing = false;

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
      if (isProcessing) return;

      final barcode = scanData.code?.trim() ?? '';
      if (barcode.isEmpty) return;

      isProcessing = true;
      await controller?.pauseCamera();

      /// 🔁 DUPLICATE CHECK
      final isDuplicate = widget.rows.any(
            (row) => row['barcodeNo']?.toString() == barcode,
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Barcode already scanned'),
              backgroundColor: Colors.red,
            ),
          );
        }

        /// Resume scanning after short delay
        await Future.delayed(const Duration(seconds: 1));
        isProcessing = false;
        await controller?.resumeCamera();
        return;
      }

      /// ✅ SAME FLOW AS RECEPTION
      if (!mounted) return;

      if (widget.rows.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DisposalAfterScan(
              barcode,
              0,
              widget.rows,
              widget.receivedQtyControllers,
              widget.valueEntered,
            ),
          ),
        );
      } else {
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

    return StreamProvider<NetworkStatus>(
      create: (_) =>
      NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              /// APP BAR
              mAppBar(
                onLeadingIconClick: () => Navigator.pop(context),
                scTitle: 'Scan Barcode',
                centerTile: false,
                showLeading: true,
              ),

              /// SCANNER BODY
              Positioned.fill(
                top: responsiveHeight(110),
                child: Container(
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
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
                            borderColor: Colors.deepOrange,
                            borderRadius: 12,
                            borderLength: 30,
                            borderWidth: 8,
                            cutOutSize:
                            MediaQuery.of(context).size.width * 0.8,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Again'),
                            onPressed: () async {
                              isProcessing = false;
                              await controller?.resumeCamera();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                            ),
                          ),
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











// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
// import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_after_scan.dart';
// import 'package:provider/provider.dart';
//
// import '../Global/app_bar.dart';
// import '../Global/constant.dart';
// import '../Global/size_config.dart';
// import '../network/network_aware.dart';
// import '../network/network_status.dart';
// import '../network/offline.dart';
//
// class DisposalScanner extends StatefulWidget {
//   final  List<dynamic> rows;
//   final List<TextEditingController>_receivedQtyControllers;
//   final List<bool>value_entered;
//   DisposalScanner(this.rows,this._receivedQtyControllers,this.value_entered,{super.key});
//   @override
//   _DisposalScannerState createState() => _DisposalScannerState();
// }
//
// class _DisposalScannerState extends State<DisposalScanner> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   String? scannedCode;
//
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null) {
//       controller!.pauseCamera();
//       controller!.resumeCamera();
//     }
//   }
//
//   void _onQRViewCreated(QRViewController qrController) {
//     this.controller = qrController;
//     qrController.scannedDataStream.listen((scanData) {
//       if (scannedCode == null) {
//         setState(() => scannedCode = scanData.code);
//         controller?.pauseCamera();
//
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DisposalAfterScan(scanData.code ?? '', 0,widget.rows,widget._receivedQtyControllers,widget.value_entered),
//           ),
//         );
//       }
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
//     return StreamProvider<NetworkStatus>(
//       create: (context) =>
//       NetworkStatusService().networkStatusController.stream,
//       initialData: NetworkStatus.Online,
//       child: NetworkAwareWidget(
//         onlineChild: Scaffold(
//           backgroundColor: Colors.white,
//           body: Stack(
//             children: [
//               /// Custom AppBar
//               mAppBar(
//                 onLeadingIconClick: () => Navigator.pop(context),
//                 scTitle: 'Scan',
//                 centerTile: false,
//                 showLeading: true,
//               ),
//
//               /// QR Scanner + result
//               Positioned.fill(
//                 top: responsiveHeight(110),
//                 bottom: responsiveHeight(0),
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 30),
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
//                         child: QRView(
//                           key: qrKey,
//                           onQRViewCreated: _onQRViewCreated,
//                           overlay: QrScannerOverlayShape(
//                             borderColor: Colors.deepOrange,
//                             borderRadius: 10,
//                             borderLength: 30,
//                             borderWidth: 8,
//                             cutOutSize: 250,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           scannedCode = null;
//                           controller?.resumeCamera();
//                         },
//                         icon: Icon(Icons.qr_code_scanner),
//                         label: Text("Scan Again"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.deepOrange,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         offlineChild: Offline(),
//       ),
//     );
//   }
// }
