import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/CBWTF/apiservice.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';

import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class HcfDetailsScreen extends StatefulWidget {
   String? hcfcode;
  HcfDetailsScreen(this.hcfcode,{super.key});
  @override
  State<HcfDetailsScreen> createState() => _HcfDetailsScreenState();
}

class _HcfDetailsScreenState extends State<HcfDetailsScreen> {
  late Future<Map<String, dynamic>> futureData;
  List rows=[];
  bool load=false;
  getRows()async{
    setState(() {
      load=true;
    });
    rows= await ApiService.Get_cbwtf_data(this.context,widget.hcfcode);
    print(rows);
    setState(() {
      rows;
      load=false;
    });
  }


  @override
  void initState() {
    super.initState();
    getRows();

  }


  // List<Map<String, dynamic>> rows = [
  //   {
  //     "color": Colors.yellow,
  //     "barcode": "BR123P6521JY",
  //     "quantity": "20",
  //     "bags": "5",
  //   },
  //   {
  //     "color": Colors.red,
  //     "barcode": "BR123P6320FR",
  //     "quantity": "60",
  //     "bags": "4",
  //   },
  //   {
  //     "color": Colors.red,
  //     "barcode": "MR12B465230V",
  //     "quantity": "25",
  //     "bags": "5",
  //   },
  //   {
  //     "color": Colors.red,
  //     "barcode": "62FREFVGT98D",
  //     "quantity": "40",
  //     "bags": "4",
  //   },
  //   {
  //     "color": Colors.blue,
  //     "barcode": "365NM4258F",
  //     "quantity": "80",
  //     "bags": "8",
  //   },
  //   {
  //     "color": Colors.yellow,
  //     "barcode": "400NM986520",
  //     "quantity": "75",
  //     "bags": "5",
  //   },
  //   {
  //     "color": Colors.yellow,
  //     "barcode": "450NMEDFGB8",
  //     "quantity": "90",
  //     "bags": "9",
  //   },
  //   {
  //     "color": Colors.yellow,
  //     "barcode": "500NM65247G",
  //     "quantity": "70",
  //     "bags": "7",
  //   },
  //   {
  //     "color": Colors.grey,
  //     "barcode": "550NM74411C",
  //     "quantity": "85",
  //     "bags": "17",
  //   },
  // ];

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
            scTitle: 'CBWTF Bio Waste Data',
            centerTile: true,
            showLeading: true,
          ),

          /// Body with tabs
          Positioned.fill(
            top: responsiveHeight(110),
            bottom: responsiveHeight(
              0,
            ), // offset to appear below custom app bar
            child: Container(
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: load?Center(child:CircularProgressIndicator(color: kPrimaryColor,)):
                  rows==null ||rows.isEmpty?Datanotfound():Table(
                    columnWidths: const {
                      0: FixedColumnWidth(6),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },

                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    children: [
                      // Table Header
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(10),
                        topLeft: Radius.circular(10))),

                        children: const [
                          SizedBox(),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              "Barcode",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kWhiteColor,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              "Quantity in Kg",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kWhiteColor,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              "Bags Received",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kWhiteColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Table Rows
                      for (int i = 0; i < rows.length; i++)
                        TableRow(
                          children: [
                            Container(height: 40, color: Colors.red),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(rows[i]['barcodeNo']==null?'NA':rows[i]['barcodeNo']),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${rows[i]['totalQuantityBagKg']} kg'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text('${rows[i]['totalNoOfBags']}'),
                            ),
                          ],
                        ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ), offlineChild: Offline()));
  }
}
