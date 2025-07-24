import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/vehicle_user/barcode_scanner_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../authentication/logout.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class BioWasteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> detail;
  const BioWasteDetailScreen(this.detail, {super.key});

  @override
  _BioWasteDetailScreenState createState() => _BioWasteDetailScreenState();
}

class _BioWasteDetailScreenState extends State<BioWasteDetailScreen> {
  List<dynamic>? wasteList;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

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
            scTitle: 'Add Bio Waste Data Details',
            centerTile: false,
            showLeading: true,
            showActions: true,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BarcodeScannerScreen(widget.detail),
                      ),
                    );

                  },
                  icon: const Icon(Icons.document_scanner_outlined),
                ),
              ),
            ],
          ),

          /// Detail Container (not full screen anymore)
          Positioned.fill(
            top: responsiveHeight(110),
            bottom: responsiveHeight(
              0,
            ), // offset to appear below custom app bar
            child: Container(
              height: responsiveHeight(100),
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 0),
              decoration: BoxDecoration(
                color: kWhiteColor,

                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              child:Column(

                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30,),
                  Container(
                    margin:EdgeInsets.symmetric(horizontal: 5,vertical: 0) ,

                //height: 120,
                    padding: EdgeInsets.symmetric(horizontal: 15,vertical: 20),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(239, 253, 255, 1),

                  borderRadius:  BorderRadius.all(
                    Radius.circular(10),

                  ),
                  border: Border.all(color: Colors.grey.shade300)
                ),

                child:Column(

                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Row 1: CBWTF Name
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Name of CBWTF : ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.detail['name'] ?? 'NA',
                        ),
                      ],
                    ),
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),

                  const SizedBox(height: 10),

                  /// Row 2: Date and HCF Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Date : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: widget.detail['date'] ?? 'NA',
                              ),
                            ],
                          ),
                          style: const TextStyle(color: Colors.black, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'HCF Code : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: widget.detail['hcfCode'] ?? 'NA',
                              ),
                            ],
                          ),
                          style: const TextStyle(color: Colors.black, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ])),
          )],
      ),
    ), offlineChild: Offline()));
  }
}
