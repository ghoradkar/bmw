import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/dispose_all.dart';
import 'package:mpcb_bio_waste/CBWTF_Disposal/waste_received_byvehicle.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/vehicle_list.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/constant.dart';
import '../Global/dataNotFound.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../authentication/logout.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class DisposalOverallCollection extends StatefulWidget {
  DisposalOverallCollection({super.key});

  @override
  State<DisposalOverallCollection> createState() =>
      _OverallDataCollectionState();
}

class _OverallDataCollectionState extends State<DisposalOverallCollection> {
  List<Map<String, dynamic>> tableData = [];
  bool isLoading = true;
  List<dynamic> rows = [];
  List<Map<String, dynamic>> selectedRows = [];
  List<Map<String, dynamic>> formattedList = [];
  bool load = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool save = false;
  List<TextEditingController> _receivedQtyControllers = [];
  List<bool> value_entered = [];
  bool data_not_found=false;

  double _getDiff(int index, double pickupQty) {
    final receivedText = _receivedQtyControllers[index].text;
    final received = double.tryParse(receivedText) ?? 0.0;
    return (pickupQty - received);
  }

  @override
  void initState() {
    super.initState();
    fetchTableData();
  }

  Future<void> SaveWaste() async {
    setState(() => save = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final username = prefs.getString('Username') ?? '';
      final userId = prefs.getString('UserId') ?? '';

      final nowUtc = DateTime.now().toUtc().toIso8601String();

      final body = List.generate(rows.length, (i) {
        final item = rows[i];

        final receivedQty =
            double.tryParse(_receivedQtyControllers[i].text.trim()) ?? 0.0;

        final pickupQty =
            (item['pickupTotalQuantityBagCbwtfKg'] ?? 0).toDouble();
        final pickupBags = item['pickupNoOfbag'] ?? 0;

        return {
          //   "lookupDetIdCategory": item['lookupDetIdCategory'],
          //   "recivedTotalNoOfBags": pickupBags,
          //   "recivedTotalQuantityBagKg":pickupQty,
          //   "totalNoOfBags": item['totalNoOfBags'],
          //   "totalQuantityBagKg": item['totalQuantityBagKg'],
          // //  "vehicleNo": widget.vehicleNo,
          //   "userId":userId
          "lookupDetIdCategory": item['lookupDetIdCategory'],
          "totalNoOfBags": item['totalNoOfBags'],
          "totalQuantityBagKg": item['totalQuantityBagKg'],
          "dispNoOfBags": pickupBags,
          "dispTotalQuantityBagKg": pickupQty,
          "cbwtfRecpDispIds": item["cbwtfRecpDispIds"],
          "userId": userId,

          // "hcfWasteId": item['hcfWasteId'],
          // "hcfId": item['hcfId'],
          // "vehicleCount": item['vehicleCount'],
          // "hcfWasteQntyDetId": item['hcfWasteQntyDetId'],
          // "hcfCode": item['hcfCode'],
          // "cbmtfFacilityName": item['cbmtfFacilityName'],
          // "barcodeNo": item['barcodeNo'],
          // "nameOfHcf": item['nameOfHcf'],
          // "totalNoOfBags": pickupBags,
          // "totalQuantityBagKg": pickupQty,
          // "hcfName": item['nameOfHcf'],
          // "userId": userId,
          // "wastecolourId": item['wastecolourId'],
          // "wasteQtyId": item['wasteQtyId'],
          // "colourType": item['colourType'],
          // "receivedBag": pickupBags,
          // "receivedQty": pickupQty,
          // "pickupNoOfbag": pickupBags,
          // "puckupQty": pickupQty,
          // "differenceInQty": pickupQty - receivedQty,
          // "hcfWasteVehicleAssignId": item['hcfWasteVehicleAssignId'],
          // "pickupTotalQuantityBagKg": pickupQty,
          // "diffrenceInBag": pickupBags - (item['receivedBag'] ?? 0),
          // "differenceInQtyCbwtf":  pickupQty - receivedQty,
          // "differenceInQtyCbwtfDisposal": pickupQty - receivedQty,
          // "assignDateCbwtf": item['assignDateCbwtf'],
          // "assignDateCbwtfDisposal": nowUtc,
          // "pickupTotalQuantityBagCbwtfKg": pickupQty,
          // "pickupTotalQuantityBagCbwtfDisposalKg":pickupQty
        };
      });

      print(jsonEncode(body));

      final response = await http.post(
        Uri.parse('$baseurl$SAVE_OVERALL_DISPOSAL_DATA'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('$baseurl$SAVE_OVERALL_DISPOSAL_DATA');
      print(response.body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData['message'])));
        showSuccessDialog(context);
      } else if (response.statusCode == 401) {
        AuthService().logout(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => save = false);
    }
  }

  Future<void> fetchTableData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final username = prefs.getString('Username') ?? '';
      final userId = prefs.getString('UserId') ?? '';

      final UserId = prefs.getString('UserId');
      final today = DateTime.now().toString().substring(0, 10);

      //  print(widget.formattedList);

      final response = await http.get(
        Uri.parse(
          '${baseurl}${GET_DISPOSAL_DATA}fromDate=$today&toDate=$today&userId=$UserId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        //  body: jsonEncode(widget.formattedList.first)
      );
      print(
        '${baseurl}${GET_DISPOSAL_DATA}fromDate=$today&toDate=$today&userId=$UserId',
      );
      print(response.body);

      if (response.statusCode == 200) {
        Map<String, dynamic> value = json.decode(response.body);

        // // Group and sort by colour
        // data.sort((a, b) {
        //   final colorOrder = ["Yellow", "Red", "Blue", "White"];
        //   return colorOrder.indexOf(a['wasteTypeColour'])
        //       .compareTo(colorOrder.indexOf(b['wasteTypeColour']));
        // });

        setState(() {
          List<dynamic> data = value['data'] ?? [];

          rows = data;
          _receivedQtyControllers = List.generate(
            rows.length,
            (_) => TextEditingController(),
          );
          value_entered = List.generate(rows.length, (_) => false);
          rows.isEmpty?data_not_found=true:data_not_found=false;

          load = false;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching table data: $e");
    }
  }

  List<Map<String, dynamic>> transformResponse(
    List responseList, {
    required int userId,
  }) {
    return responseList.map((item) {
      return {
        "cbwtfRecpDispIds": item["cbwtfRecpDispIds"],
        "totalNoOfBags": item["totalNoOfBags"],
        "totalQuantityBagKg": item["totalQuantityBagKg"],
        "pickupNoOfbag": item["pickupNoOfbag"],
        "pickupTotalQuantityBagCbwtfKg": item["pickupTotalQuantityBagCbwtfKg"],
        "lookupDetIdCategory": 3,
        "userId": userId,
      };
    }).toList();
  }

  Future<void> fetchdetailTableData(data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final username = prefs.getString('Username') ?? '';
      final userId = prefs.getString('UserId') ?? '';

      final UserId = prefs.getString('UserId');
      final today = DateTime.now().toString().substring(0, 10);
      formattedList = transformResponse(data, userId: int.parse(userId));

      //  print(widget.formattedList);

      final response = await http.post(
        Uri.parse('${baseurl}${GET_OVERALL_DISPOSAL_DATA}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(formattedList.first),
      );
      print('${baseurl}${GET_OVERALL_DISPOSAL_DATA}');
      print(jsonEncode(formattedList.first));
      print(response.body);

      if (response.statusCode == 200) {
        Map<String, dynamic> value = json.decode(response.body);
        List<dynamic> data = value['data'] ?? [];

        // Group and sort by colour
        data.sort((a, b) {
          final colorOrder = ["Yellow", "Red", "Blue", "White"];
          return colorOrder
              .indexOf(a['wasteTypeColour'])
              .compareTo(colorOrder.indexOf(b['wasteTypeColour']));
        });

        setState(() {
          rows = data;
          _receivedQtyControllers = List.generate(
            rows.length,
            (_) => TextEditingController(),
          );
          value_entered = List.generate(rows.length, (_) => false);
          load = false;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching table data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<NetworkStatus>(
        create: (context) =>
        NetworkStatusService().networkStatusController.stream,
        initialData: NetworkStatus.Online,
        child: NetworkAwareWidget(
            onlineChild:Scaffold(
              drawer: AppDrawer(),
              key: _scaffoldKey,
              body: Stack(
                children: [
                  /// Custom Gradient AppBar
                  mAppBar(
                    leadingWidget: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    showLeading: true,
                    //onLeadingIconClick: () => Navigator.pop(context),
                    scTitle: 'Bio Waste Received By Vehicle',
                    centerTile: false,
                   // showLeading: true,
                  ),

                  /// Body with tabs
                  Positioned.fill(
                    top: 100,
                    bottom: responsiveHeight(
                      0,
                    ), // offset to appear below custom app bar
                    child: Container(
                      //height: responsiveHeight(90),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: kWhiteColor,

                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(40),
                          topLeft: Radius.circular(40),
                        ),
                      ),
                      child:
                      load
                          ? Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      )
                          : data_not_found?Datanotfound():SingleChildScrollView(child:Column(
                        children: [
                          SizedBox(height: 20),
                        _buildTable(),
                          SizedBox(height: 20),
                         // Spacer(),
                         //  save
                         //      ? Center(
                         //    child: CircularProgressIndicator(
                         //      color: kPrimaryColor,
                         //    ),
                         //  )

                              SizedBox(
                                width: responsiveWidth(150),
                                child: AppButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 15,
                                  ),
                                  text: 'Dispose',
                                  onPressed: () {
                                    selectedRows.isEmpty?
                                        {  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please Select Waste to Dispose')),
                                    ),}:
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DisposeAll(selectedRows
                                      )),
                                    );

                                  },
                                  color: Colors.deepOrange,
                                ),
                              ),

                        ],
                      ),
                    ),
                  ),
                  )],
              ),
            ), offlineChild: Offline()));
  }




  // Widget _buildTable() {
  //   return Table(
  //       border: TableBorder.all(
  //         color: Colors.grey.shade400,
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //       columnWidths: const {
  //         0: FlexColumnWidth(0.13),
  //         1: FlexColumnWidth(1),
  //         2: FlexColumnWidth(1),
  //
  //         4: FlexColumnWidth(1.5),
  //
  //         6: FlexColumnWidth(1),
  //         7: FlexColumnWidth(1),
  //       },
  //       children: [
  //         TableRow(
  //           decoration: const BoxDecoration(
  //             borderRadius: BorderRadius.only(
  //               topRight: Radius.circular(10),
  //               topLeft: Radius.circular(10),
  //             ),
  //             color: Colors.grey,
  //           ),
  //           children: _tableHeaders([
  //             " ",
  //             "Category",
  //
  //             "Qty by HCF",
  //
  //             'Received By CBWTF',
  //             "Disposed By CBWTF",
  //
  //             "Difference in Qty",
  //             "",
  //           ]),
  //         ),
  //         for (int i = 0; i < rows.length; i++) _buildDataRow(rows[i], i),
  //       ],
  //
  //   );
  // }
  //
  // TableRow _buildDataRow(Map<String, dynamic> item, int index) {
  //   final colourType = item['wasteTypeColour'] ?? 'Green';
  //   final pickupQty = (item['totalQuantityBagKg'] ?? 0).toDouble();
  //   final bycbwtf = (item['pickupTotalQuantityBagCbwtfKg'] ?? 0).toDouble();
  //
  //   final color = _getColorFromType(colourType);
  //   final diff = _getDiff(index, bycbwtf);
  //
  //   return TableRow(
  //     children: [
  //       Container(height: 70, color: color),
  //       _tableCell(item['wasteTypeColour']),
  //
  //       _tableCell("$pickupQty kg"),
  //
  //       _tableCell("$bycbwtf kg"),
  //
  //       // _tableCell("$byvehicle kg"),
  //       Padding(
  //         padding: const EdgeInsets.only(
  //           top: 10,
  //           bottom: 10,
  //           left: 5,
  //           right: 5,
  //         ),
  //         child: TextFormField(
  //           controller: _receivedQtyControllers[index],
  //           style: TextStyle(fontSize: 11),
  //           onChanged:
  //               (_) => setState(() {
  //                 if (_receivedQtyControllers[index].text.isEmpty) {
  //                   value_entered[index] = false;
  //                 } else {
  //                   value_entered[index] = true;
  //                 }
  //               }),
  //           keyboardType: TextInputType.number,
  //           decoration: InputDecoration(
  //             suffixText: 'Kg',
  //             suffixStyle: const TextStyle(fontSize: 10),
  //             isDense: true,
  //             contentPadding: const EdgeInsets.symmetric(
  //               vertical: 6,
  //               horizontal: 8,
  //             ),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(6),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderSide: BorderSide(color: Colors.grey.shade400),
  //               borderRadius: BorderRadius.circular(6),
  //             ),
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //       _tableCell("${diff.toStringAsFixed(2)} kg"),
  //
  //       Center(
  //         child: IconButton(
  //           onPressed: () {
  //             setState(() {
  //               print(value_entered[index]);
  //               if (_receivedQtyControllers[index].text.isEmpty) {
  //                 setState(() {
  //                   value_entered[index] = false;
  //                 });
  //               }
  //               value_entered[index] = !value_entered[index];
  //             });
  //           },
  //           icon: Icon(Icons.check_circle),
  //           color: value_entered[index] ? Colors.green : Colors.grey,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _buildTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.25),

        3: FlexColumnWidth(1),

        4: FlexColumnWidth(1),
        5: FlexColumnWidth(0.9),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),

            gradient: LinearGradient(
              colors: [kPrimaryColor, kPrimaryDarkColor],
            ),
          ),
          children: _tableHeaders([
            "Sr.No",
            "Vehicle No",

            "Reception Date",

            'Total No of Bags',
            "Total Waste Generated",

            "Select",
          ]),
        ),
        for (int i = 0; i < rows.length; i++) _buildDataRow(rows[i], i),
      ],
    );
  }

  String formatDate(String dateStr) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
  }

  TableRow _buildDataRow(Map<String, dynamic> item, int index) {
    bool isSelected = selectedRows.contains(item);


    return TableRow(
      children: [
        // Container(height: 70, color: color),
        _tableCell("${index + 1}"),

        _tableCell(item['vehicleNo']),
        _tableCell(formatDate(item['assignDateCbwtf'])),

        _tableCell(item['totalNoOfBags'].toString()),
        _tableCell(item['totalQuantityBagKg'].toString()),
        // ✅ Select column
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Center(
            child: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedRows.add(item);
                  } else {
                    selectedRows.remove(item);
                  }
                });
              },
            ),
          ),
        ),


      ],
    );
  }

  List<Widget> _tableHeaders(List<String> headers) {
    return headers
        .map(
          (h) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              h,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Color _getColorFromType(String type) {
    switch (type) {
      case 'Red':
        return Colors.red;
      case 'Yellow':
        return Colors.yellow;
      case 'Blue':
        return Colors.blue;
      case 'White':
        return Colors.white;
      case 'Green':
        return Colors.green;
      default:
        return Colors.grey.shade300;
    }
  }

  void showSuccessDialog(BuildContext context) {
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
                      // Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WasteReceivedByvehicle(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                      //Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.biowaste_received_byvehicle));
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
}
