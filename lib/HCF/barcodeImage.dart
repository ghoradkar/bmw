import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';

import 'dart:io';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
// adjust import

class BarcodeImageScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const BarcodeImageScreen({super.key, required this.imageBytes});

  /// Detect if it's a PDF (starts with %PDF)
  bool _isPdf(Uint8List data) {
    final pdfHeader = '%PDF'.codeUnits;
    return data.length >= 4 &&
        data.sublist(0, 4).every((byte) => pdfHeader.contains(byte));
  }

  Future<void> _openPdf(BuildContext context) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/barcode.pdf';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    await OpenFile.open(filePath);
    Navigator.pop(context); // Optional: close this screen after opening PDF
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    // If PDF, open it and show loading spinner
    if (_isPdf(imageBytes)) {
      _openPdf(context); // handle in background
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Else show image
    return Scaffold(
      body: Stack(
        children: [
          mAppBar(
            scTitle: 'Generated Barcode',
            centerTile: true,
            showLeading: true,
            onLeadingIconClick: () => Navigator.pop(context),
          ),
          Positioned.fill(
            top: responsiveHeight(110),
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              child: Center(
                child: Image.memory(imageBytes),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
