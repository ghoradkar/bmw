import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/HCF/add_bio_waste.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/constant.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';
import 'after_Save.dart';
import 'bio_waste_summary.dart';

class BioWasteSummaryTable extends StatefulWidget {
  List<Map<String,dynamic>> tableData;
  BioWasteSummaryTable(this.tableData,{super.key});
  @override
  State<BioWasteSummaryTable> createState() => _TableScreenState();
}

class _TableScreenState extends State<BioWasteSummaryTable> {
  List<Map<String, dynamic>> groupedData = [];
  List<Map<String, dynamic>> selectedWasteEntries = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading=false;
  Future<void> SaveBioWaste() async {
    print('length');
    print(widget.tableData.length);
    print(groupedData.length);
    setState(() {
      isLoading=true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('Token');

    Map<String,dynamic> user=jsonDecode(prefs.getString('user')!);
    print(user);
    final payload = BioWasteMapper.buildPayload(
      tableData: widget.tableData,

      hcfId: user['hcfId'],
      hcfCode: user['hcfCode'],
      wasteQntyDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      userId: user['userId'],
      createdDate: DateTime.now().toIso8601String(),
      updatedDate: DateTime.now().toIso8601String(),
      macId: "00-14-22-01-23-45",
      ipAddress: "192.168.1.1",
    );
    print('payload');
    print(DateTime.now().toIso8601String());
    print(DateTime.now().toLocal().toIso8601String());
    print(DateTime.now().toUtc());
    print(jsonEncode(payload));


    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final response = await http.post(
          Uri.parse('${baseurl}${ADD_UPDATE_WASTE}'),
          headers: headers,
          body: jsonEncode(payload)
      );

      print('${baseurl}${ADD_UPDATE_WASTE}');
      if (response.statusCode == 201) {
        print(response.body);
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];
          print('data');
          print(data.length);
          print(data);
          widget.tableData.clear();
          groupedData.clear();

          // final int hcfWasteId = data['hcfWasteId'];
          //
          // List<dynamic> wasteList = data['wasteList'] ?? [];
          // print(wasteList);

          // for (var waste in wasteList) {
          //   final hcfWasteQntyId = waste["hcfWasteQntyId"];
          //   final List<dynamic> wasteDetList = waste["wasteDetList"] ?? [];
          //
          //   for (var det in wasteDetList) {
          //     final hcfWasteQntyDetId = det["hcfWasteQntyDetId"];
          //
          //     selectedWasteEntries.add({
          //       "hcfWasteId": hcfWasteId,
          //       "hcfWasteQntyId": hcfWasteQntyId,
          //       "hcfWasteQntyDetId": hcfWasteQntyDetId,
          //     });
          //   }
          // }


          showSuccessDialog(context,data);



        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Waste Failed')),
          );
          print("API returned non-success status.");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication Error')),
        );
        print("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching bio waste summary')),
      );
      print('Error fetching bio waste summary: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _groupTableData();
  }

  void _groupTableData() {
    Map<String, Map<String, dynamic>> tempMap = {};

    for (var item in widget.tableData) {
      String color = item['color'];
      double quantity = double.tryParse(item['quantity'].toString()) ?? 0;

      if (tempMap.containsKey(color)) {
        tempMap[color]!['quantity'] += quantity;
        tempMap[color]!['bags'] += 1;
      } else {
        tempMap[color] = {
          'color': color,
          'category': item['category'],
          'quantity': quantity,
          'bags': 1,
        };
      }
    }

    groupedData = tempMap.values.toList();
  }

  Color _getColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return Colors.yellow;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.lightBlue;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return StreamProvider<NetworkStatus>(
        create: (context) =>
    NetworkStatusService().networkStatusController.stream,
    initialData: NetworkStatus.Online,
    child: NetworkAwareWidget(
    onlineChild: Scaffold(
    key: _scaffoldKey,
    drawer: AppDrawer(),
    body: Stack(
    children: [
    /// Custom Gradient AppBar
    mAppBar(
    scTitle: 'HCF Bio Waste Data',
    centerTile: true,
      onLeadingIconClick: () => Navigator.pop(context),
    showLeading: true,

    ),

    /// Body with tabs
    Positioned.fill(
    top: responsiveHeight(110),
    bottom: responsiveHeight(0),// offset to appear below custom app bar
    child: Container(
    padding:const EdgeInsets.all(15) ,

    decoration: BoxDecoration(
    color: kWhiteColor,
    borderRadius: const BorderRadius.only(
    topRight: Radius.circular(40),
    topLeft: Radius.circular(40),
    ),
    ),
    child: Column(
          children: [

            _buildDataTable(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                SizedBox(
                  width: responsiveWidth(150),
                  child: AppButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 15,
                    ),
                    text: 'Save',
                    onPressed:(){
                      groupedData.isNotEmpty && widget.tableData.isNotEmpty?
                      SaveBioWaste():{ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please Add waste'), backgroundColor: Colors.red),
                      )};
                      },
                    color: Colors.deepOrange,
                  ),
                ),
                SizedBox(
                  width: responsiveWidth(150),
                  child: AppButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 15,
                    ),
                    text: 'Cancel',
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false, // User must tap button
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Success Tick Icon
                                 // Image.asset(success),
                                  const SizedBox(height: 24),

                                  // Success Text
                                  const Text(
                                    "Are your sure you want to go back ?",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 24),

                                  // OK Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [SizedBox(
                                    width: responsiveWidth(120),
                                    child: AppButton(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 15,
                                      ),
                                      text: 'No',
                                      onPressed: () {
                                        Navigator.pop(context);

                                      },
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                    width: responsiveWidth(120),
                                    child: AppButton(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 15,
                                      ),
                                      text: 'Yes',
                                      onPressed: () async{
                                        groupedData.clear();
                                        widget.tableData.clear();
                                        SharedPreferences prefs = await SharedPreferences.getInstance();



                                        prefs.remove('tableData');
                                        Navigator.pop(context);
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddBioWasteDataTab(),
                                          ),
                                        );


                                      },
                                      color: Colors.deepOrange,
                                    ),
                                  ),]),
                                ],
                              ),
                            ),
                          );
                        },
                      );




                    },
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )])), offlineChild: Offline()));
  }


  Widget _buildDataTable() {
    return  Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              topLeft: Radius.circular(10),
            ),
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0099CC)],
            ),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Sr. No",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Category",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Total Weight (kg)",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "No. of Bags",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        for (int i = 0; i <groupedData.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color:
              i % 2 == 0
                  ? Colors.white
                  : Colors.grey.shade50,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "${i + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color:
                       groupedData[i]['color']=='Yellow'?Colors.yellow: groupedData[i]['color']=='Blue'?Colors.blue: groupedData[i]['color']=='Red'?Colors.red:Colors.white,

                        shape: BoxShape.rectangle,
                        border: Border.all(
                          color:
                          groupedData[i]['category'] ==
                              'White'
                              ? Colors.black
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      groupedData[i]['category'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  enabled: false,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  initialValue:
                  groupedData[i]['quantity'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  onChanged: (val) {
                    groupedData[i]['quantity'] =
                        int.tryParse(val) ?? 0;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  enabled: false,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  initialValue:
                  groupedData[i]['bags'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    groupedData[i]['bags'] =
                        int.tryParse(val) ?? 0;
                  },
                ),
              ),
            ],
          ),
      ],
    );
    // return Expanded(
    //   child: ListView.builder(
    //     itemCount: groupedData.length,
    //     itemBuilder: (context, index) {
    //       final data = groupedData[index];
    //       return Container(
    //         padding: const EdgeInsets.symmetric(vertical: 12),
    //         decoration: BoxDecoration(
    //           border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
    //         ),
    //         child: Row(
    //           children: [
    //             Expanded(child: Center(child: Text('${index + 1}'))),
    //             Expanded(
    //               child: Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children: [
    //                   Container(
    //                     width: 16,
    //                     height: 16,
    //                     margin: const EdgeInsets.only(right: 6),
    //                     decoration: BoxDecoration(
    //                       color: _getColor(data['color']),
    //                       border: Border.all(color: Colors.black),
    //                     ),
    //                   ),
    //                   Text(data['category']),
    //                 ],
    //               ),
    //             ),
    //             Expanded(
    //               child: Center(child: Text('${data['totalQuantity']}')),
    //             ),
    //             Expanded(
    //               child: Center(child: Text('${data['bagCount']}')),
    //             ),
    //           ],
    //         ),
    //       );
    //     },
    //   ),
    // );
  }
}
void showSuccessDialog(BuildContext context,wasteList) {
  showDialog(
    context: context,
    barrierDismissible: false, // User must tap button
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Tick Icon
              Image.asset(success),
              const SizedBox(height: 24),

              // Success Text
              const Text(
                "Bio Waste Data\nadded successfully.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              // OK Button
              SizedBox(
                width: responsiveWidth(180),
                child: AppButton(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 15,
                  ),
                  text: 'Ok',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BioWasteDetailTableScreen(wasteList),
                      ),
                    );
                  },
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(colors: [Colors.green, Colors.lightGreen]),
          //     borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          //   ),
          //   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          //   child: Row(
          //     children: const [
          //       Expanded(child: Text("Color", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          //       Expanded(child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          //       Expanded(child: Text("Total Quantity", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          //       Expanded(child: Text("No. of Bags", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          //     ],
          //   ),
          // ),
          // if (data.isEmpty)
          //   Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: Text("No data available."),
          //   )
          // else
          //   ...data.map((row) {
          //     return Padding(
          //       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          //       child: Row(
          //         children: [
          //           Expanded(child: Text(row['color'] ?? '-')),
          //           Expanded(child: Text(row['category'] ?? '-')),
          //           Expanded(child: Text("${row['totalQuantity'] ?? 0}")),
          //           Expanded(child: Text("${row['noOfBags'] ?? 0}")),
          //         ],
          //       ),
          //     );
          //   }).toList(),
