import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/CBWTF_Reception/overall_Data_collection.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart'; // for Future

class BiowasteReceivedByvehicle extends StatefulWidget {
  final String vehicleNo;
  BiowasteReceivedByvehicle(this.vehicleNo, {super.key});
  @override
  _BiowasteReceivedByvehicleState createState() =>
      _BiowasteReceivedByvehicleState();
}

class _BiowasteReceivedByvehicleState extends State<BiowasteReceivedByvehicle> {
  bool _isLoading = true;
  List<dynamic> _tableData = [];

  @override
  void initState() {
    super.initState();
    fetchAssignedHCFData();
  }

  Future<void> fetchAssignedHCFData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final username = prefs.getString('Username');
      final UserId = prefs.getString('UserId');

      final response = await http.get(
        Uri.parse(
          '${baseurl}${GET_VEHICLE_DETAILS}${widget.vehicleNo}/$UserId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('${baseurl}${GET_VEHICLE_DETAILS}${widget.vehicleNo}/$UserId');
      if (response.statusCode == 200) {
        final value = jsonDecode(response.body);

        setState(() {
          _tableData =
              value['data']
                  .map(
                    (e) => {
                      'date': e['vehicleAssignDateStr'] ?? '',
                      'name': e['hcfName'] ?? '',
                      'bags': e['totalNoOfBags'] ?? 0,
                      'waste': e['totalQuantityBagKg'] ?? 0,
                    },
                  )
                  .toList();
          _isLoading = false;
        });
      } else {
        // handle error
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching HCFs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching HCFs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Future<void> fetchAssignedHCFData() async {
  //   try {
  //     // Replace this delay and list with your actual API call using http.get()
  //     await Future.delayed(const Duration(seconds: 2));
  //     final responseData = [
  //       {
  //         "date": "15/06/2025",
  //         "name": "Manipal Hospital",
  //         "bags": 60,
  //         "waste": 600
  //       },
  //       {
  //         "date": "13/06/2025",
  //         "name": "Jupiter Hospital",
  //         "bags": 25,
  //         "waste": 250
  //       },
  //       {
  //         "date": "12/06/2025",
  //         "name": "Deenanath Mangeshkar Hospital",
  //         "bags": 40,
  //         "waste": 320
  //       },
  //       {
  //         "date": "11/06/2025",
  //         "name": "Kokilaben Hospital",
  //         "bags": 80,
  //         "waste": 1200
  //       },
  //     ];
  //
  //     setState(() {
  //       _tableData = responseData;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //       _tableData = [];
  //     });
  //     // Optionally show a snackbar or alert dialog here
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();
    return StreamProvider<NetworkStatus>(
      create:
          (context) => NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              /// Custom Gradient AppBar
              mAppBar(
                onLeadingIconClick: () => Navigator.pop(context),
                scTitle: t.translate('bmw_received_by_vehicle'),
                centerTile: false,
                showLeading: true,
                showActions: true,
                actions: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popAndPushNamed(AppRoutes.reception_scan);
                      },
                      icon: Icon(Icons.document_scanner_outlined),
                    ),
                  ),
                ],
              ),

              /// Body with tabs
              Positioned.fill(
                top: responsiveHeight(110),
                bottom: responsiveHeight(
                  0,
                ), // offset to appear below custom app bar
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                  decoration: BoxDecoration(
                    color: kWhiteColor,

                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                    ),
                  ),
                  child:  _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: kPrimaryColor,
                    ),
                  )
                      : _tableData.isEmpty || _tableData == null
                      ? SizedBox(
                      height: 480,
                      child: Datanotfound())
                      : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child:Column(
                    children: [

                            Table(
                                    border: TableBorder.all(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    columnWidths: const {
                                      0: FlexColumnWidth(1),
                                      1: FlexColumnWidth(2),
                                      2: FlexColumnWidth(3),
                                      3: FlexColumnWidth(2),
                                      4: FlexColumnWidth(3),
                                    },
                                    children: [
                                      TableRow(
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10),
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              kPrimaryColor,
                                              kPrimaryDarkColor,
                                            ],
                                          ),
                                        ),
                                        children:  [
                                          _TableHeaderCell(t.translate('srno')),
                                          _TableHeaderCell(t.translate('date'),),
                                          _TableHeaderCell(t.translate('hcf_name'),),
                                          _TableHeaderCell(
                                              t.translate('total_bags'),
                                          ),
                                          _TableHeaderCell(
                                              t.translate('total_waste'),
                                          ),
                                        ],
                                      ),
                                      ...List.generate(_tableData.length, (
                                        index,
                                      ) {
                                        final row = _tableData[index];
                                        return TableRow(
                                          children: [
                                            _TableCell("${index + 1}"),
                                            _TableCell(row['date']),
                                            _TableCell(row['name']),
                                            _TableCell("${row['bags']}"),
                                            _TableCell(
                                              "${row['waste']}",
                                              isBold: true,
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),




                      // SizedBox(
                      //   width: responsiveWidth(200),
                      //   child: AppButton(
                      //     padding: const EdgeInsets.symmetric(
                      //       vertical: 10,
                      //       horizontal: 15,
                      //     ),
                      //     text: 'Collect All',
                      //     onPressed: () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder:
                      //               (_) =>
                      //               OverallDataCollection(),
                      //         ),
                      //       );
                      //     },
                      //     color: Colors.deepOrange,
                      //   ),
                      // ),

                    ],
                  ),
                ),
              ),

          )]),
        ),
        offlineChild: Offline(),
      ),
    );
  }
}

/// Table Header Cell Widget
class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Table Data Cell Widget
class _TableCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const _TableCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
