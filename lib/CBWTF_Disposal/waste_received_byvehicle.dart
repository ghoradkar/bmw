import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_after_scan.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/disposal_overall_colection.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../CBWTF_Reception/overall_Data_collection.dart';
import '../Global/AppDrawer.dart';
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

class WasteReceivedByvehicle extends StatefulWidget {
  @override
  _WasteReceivedByvehicleState createState() => _WasteReceivedByvehicleState();
}

class _WasteReceivedByvehicleState extends State<WasteReceivedByvehicle> {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _tableData = [];
  List <Map<String, dynamic>> formattedList=[];

  @override
  void initState() {
    super.initState();
    fetchAssignedHCFData();
  }
  String formatDate(String dateStr) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
  }
  // List<Map<String, dynamic>> transformResponse(
  //     List responseList,
  //     {required int userId}) {
  //   return responseList.map((item) {
  //     return {
  //       "cbwtfRecpDispIds": item["cbwtfRecpDispIds"],
  //       "totalNoOfBags": item["totalNoOfBags"],
  //       "totalQuantityBagKg": item["totalQuantityBagKg"],
  //       "pickupNoOfbag": item["pickupNoOfbag"],
  //       "pickupTotalQuantityBagCbwtfKg": item["pickupTotalQuantityBagCbwtfKg"],
  //       "lookupDetIdCategory": 3,
  //       "userId": userId
  //     };
  //   }).toList();
  // }
  Future<void> fetchAssignedHCFData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final UserId = prefs.getString('UserId');
      final today=DateTime.now().toString().substring(0,10);

      final response = await http.get(
        Uri.parse('${baseurl}${GET_WASTE_RECEIVED_BY_VEHICLE}$UserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },);
      print('${baseurl}${GET_WASTE_RECEIVED_BY_VEHICLE}$UserId');
      print(response.body);
      print(response.statusCode);
    if (response.statusCode == 201
    ) {
        Map<String,dynamic>value = jsonDecode(response.body);
        List data=value['data'];
        print(data);
        // formattedList=transformResponse(data, userId: int.parse(UserId!));
        // print(formattedList);




      setState(() {
        _tableData = data.map((e) => {
         'wasteId':e['hcfWasteId'],
          'date': formatDate(e['wasteQntyDateStr']),
          'name': e['hcfName'],
          'bags': e['totalNoOfBags'],
          'waste': e['totalQuantityBagKg'],
        }).toList();
        _isLoading = false;
      });
      print(_tableData);
    } else {
      // handle error
      setState(() => _isLoading = false);
    }}
    catch (e) {
      print('Error fetching HCFs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching HCFs: $e'), backgroundColor: Colors.red),
      );
    }}

  //
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
    SizeConfig().init(context);
    return StreamProvider<NetworkStatus>(
        create: (context) =>
        NetworkStatusService().networkStatusController.stream,
        initialData: NetworkStatus.Online,
        child: NetworkAwareWidget(
        onlineChild:Scaffold(
        key: _scaffoldKey,

        drawer: AppDrawer(),
        backgroundColor: Colors.white,
        body: Stack(
            children: [
              /// Custom Gradient AppBar
              mAppBar(
                  //onLeadingIconClick: () => Navigator.pop(context),
                  scTitle: t.translate('bmw_details_for_disposal'),
                  centerTile: false,
                  leadingWidget: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  showLeading: true,
                  showActions: true,
                  actions: [
                    Padding(padding:EdgeInsets.symmetric(horizontal: 10) ,child:IconButton(onPressed: (){
                      Navigator.of(context).pushNamed(AppRoutes.disposal_scan);
                    }, icon: Icon(Icons.document_scanner_outlined)))]
              ),

              /// Body with tabs
              Positioned.fill(
                  top: responsiveHeight(110),
                  bottom: responsiveHeight(
                    0,
                  ), // offset to appear below custom app bar
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 30),
                    decoration: BoxDecoration(
                      color: kWhiteColor,

                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(40),
                        topLeft: Radius.circular(40),
                      ),
                    ),
                    child: _tableData.isEmpty||_tableData==null?Datanotfound():SingleChildScrollView(child:Column(children: [
                    _isLoading?Center(child:CircularProgressIndicator(color: kPrimaryColor,)):
                   Table(
                      border: TableBorder.all(color: Colors.grey.shade400, width: 1,
                        borderRadius: BorderRadius.all(Radius.circular(10)), ),

                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1.7),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.5),
                       // 5: FlexColumnWidth(1),

                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),

                            gradient: LinearGradient(

                              colors: [kPrimaryColor, kPrimaryDarkColor],
                            ),
                          ),
                          children: [
                            _TableHeaderCell(t.translate('srno')),
                            _TableHeaderCell(t.translate('date')),
                            _TableHeaderCell(t.translate('hcf_name')),
                            _TableHeaderCell(t.translate('total_bags')),
                            _TableHeaderCell(t.translate('total_waste')),
                            _TableHeaderCell(t.translate('action')),

                          ],
                        ),
                        ...List.generate(_tableData.length, (index) {
                          final row = _tableData[index];
                          return TableRow(
                            children: [
                              _TableCell("${index + 1}"),
                              _TableCell(row['date']),
                              _TableCell(row['name']),
                              _TableCell("${row['bags']}"),
                              _TableCell("${row['waste']}", isBold: true),
                              GestureDetector(
                                  onTap: (){
                                    print(_tableData[index]);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DisposalAfterScan('0',row['wasteId'],[],[],[]),
                                      ),
                                    );

                                  },
                                  child:Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.lightBlue,
                                      size: 20,
                                    ),
                                  ))

                            ],
                          );
                        }),
                      ],
                    ),
                   SizedBox(height: 15,),
                   //  Spacer(),
                   //    SizedBox(
                   //      width: responsiveWidth(200),
                   //      child: AppButton(
                   //        padding: const EdgeInsets.symmetric(
                   //          vertical: 10,
                   //          horizontal: 15,
                   //        ),
                   //        text: 'Dispose All',
                   //        onPressed: () {
                   //          Navigator.push(
                   //            context,
                   //            MaterialPageRoute(
                   //              builder: (_) => DisposalOverallCollection(),
                   //            ),
                   //          );
                   //
                   //        },
                   //        color: Colors.deepOrange,
                   //      ),
                   //    ),

                  ])))
              )])
        ), offlineChild: Offline()));
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
            fontSize: 10,
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








