import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/CBWTF_Reception/vehicle_list.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/constant.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../authentication/logout.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class OverallDataCollection extends StatefulWidget {
  final String vehicleNo;
  const OverallDataCollection(this.vehicleNo,{super.key});

  @override
  State<OverallDataCollection> createState() => _OverallDataCollectionState();
}

class _OverallDataCollectionState extends State<OverallDataCollection> {
  List<Map<String, dynamic>> tableData = [];
  bool isLoading = true;
  List<dynamic> rows = [];
  bool load=false;
  bool save=false;
  List<TextEditingController> _receivedQtyControllers = [];
  List<TextEditingController> _receivedbagsControllers = [];
  List<bool> value_entered = [];

  double _getDiff(int index, double pickupQty) {
    final receivedText = _receivedQtyControllers[index].text;
    final received = double.tryParse(receivedText) ?? 0.0;
    return (pickupQty-received);
  }

  @override
  void initState() {
    super.initState();
    fetchTableData();
  }
  bool isSaving = false;

  Future<void> SaveWaste() async {
    if (isSaving) return; // 🚫 Prevent multiple calls
    isSaving = true;
    setState(() => save = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final userId = prefs.getString('UserId') ?? '';

      final nowUtc = DateTime.now().toUtc().toIso8601String();

      final body = List.generate(rows.length, (i) {
        final item = rows[i];
        final receivedBags=double.tryParse(_receivedbagsControllers[i].text.trim())??item['totalNoOfBags'];
        final receivedQty =
            double.tryParse(_receivedQtyControllers[i].text.trim()) ?? 0.0;
        final pickupQty =
        (item['pickupTotalQuantityBagCbwtfKg'] ?? 0).toDouble();

        return {
          "lookupDetIdCategory": item['lookupDetIdCategory'],
          "recivedTotalNoOfBags": receivedBags,
          "recivedTotalQuantityBagKg": receivedQty,
          "totalNoOfBags": item['totalNoOfBags'],
          "totalQuantityBagKg": item['totalQuantityBagKg'],
          "vehicleNo": widget.vehicleNo,
          "userId": userId,
        };
      });

      print("Payload => ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$baseurl$SAVE_OVERALL_DATA'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("API: $baseurl$SAVE_OVERALL_DATA");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
        showSuccessDialog(context);
      } else if (response.statusCode == 401) {
        AuthService().logout(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      isSaving = false;
      if (mounted) setState(() => save = false);
    }
  }


  Future<void> fetchTableData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final username = prefs.getString('Username') ?? '';
      final userId = prefs.getString('UserId') ?? '';

      final response = await http.get(
        Uri.parse('${baseurl}${GET_OVERALL_DATA}${widget.vehicleNo}/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('${baseurl}${GET_OVERALL_DATA}${widget.vehicleNo}/$userId');

      if (response.statusCode == 200) {
        Map<String, dynamic> value = json.decode(response.body);
        List<dynamic> data = value['data'] ?? [];
        print(data);
        print(data.length);

        // Group and sort by colour
        data.sort((a, b) {
          final colorOrder = ["Yellow", "Red", "Blue", "White"];
          return colorOrder.indexOf(a['wasteTypeColour'])
              .compareTo(colorOrder.indexOf(b['wasteTypeColour']));
        });

        setState(() {
          rows = data;
          _receivedQtyControllers = List.generate(
            rows.length,
                (_) => TextEditingController(),
          );
          _receivedbagsControllers=List.generate(rows.length,  (_) => TextEditingController(),);
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
              body: Stack(
                children: [
                  /// Custom Gradient AppBar
                  mAppBar(
                    onLeadingIconClick: () => Navigator.pop(context),
                    scTitle: 'Bio Waste Received By Vehicle',
                    centerTile: false,
                    showLeading: true,
                  ),

                  /// Body with tabs
                  Positioned.fill(
                    top: responsiveHeight(110),
                    bottom: responsiveHeight(
                      0,
                    ), // offset to appear below custom app bar
                    child: Container(
                      height: responsiveHeight(100),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 30),
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
                          : Column(
                        children: [
                          SizedBox(height: 20),
                          _buildTable(),
                          Spacer(),
                          save
                              ? Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryColor,
                            ),
                          )
                              : SafeArea(child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: responsiveWidth(150),
                                child: AppButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 15,
                                  ),
                                  text: 'Save',
                                  onPressed: () {
                                    bool isValid = true;

                                    for (
                                    int i = 0;
                                    i < _receivedQtyControllers.length;
                                    i++
                                    ) {
                                      final text =
                                      _receivedQtyControllers[i].text
                                          .trim();

                                      if (text.isEmpty) {
                                        // Mark that this row does NOT have a value
                                        value_entered[i] = false;
                                        isValid = false;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill all Received Quantity fields.',
                                            ),
                                          ),
                                        );
                                        return;
                                      } else {
                                        value_entered[i] = true;

                                        SaveWaste();
                                      }
                                    }

                                    // // Trigger error message if any value is empty
                                    // if (!isValid) {
                                    //   ScaffoldMessenger.of(
                                    //     context,
                                    //   ).showSnackBar(
                                    //     const SnackBar(
                                    //       content: Text(
                                    //         'Please fill all Received Quantity fields.',
                                    //       ),
                                    //     ),
                                    //   );
                                    //   return; // Exit early, do not proceed
                                    // }
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
                                  onPressed: () => Navigator.pop(context),
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                          ) ],
                      ),
                    ),
                  ),
                ],
              ),
            ), offlineChild: Offline()));
  }

  Widget _buildTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      columnWidths: const {
        0: FlexColumnWidth(0.15),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(0.8),
        3: FlexColumnWidth(0.8),
        4: FlexColumnWidth(1.3),
        5: FlexColumnWidth(1.3),

        6: FlexColumnWidth(1),
        7: FlexColumnWidth(0.7),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              topLeft: Radius.circular(10),
            ),
            gradient: LinearGradient(
              colors: [kPrimaryColor, kPrimaryDarkColor],
            ),
          ),
          children: _tableHeaders([
            "",
            "Category",
            "Total Bags",

            "Total Weight",

            'Received Bags',
            'Received Weight',

            "Difference in Qty",
            "",
          ]),
        ),
        for (int i = 0; i < rows.length; i++) _buildDataRow(rows[i], i),
      ],
    );
  }

  TableRow _buildDataRow(Map<String, dynamic> item, int index) {

    final colourType = item['wasteTypeColour'] ?? 'Green';
    final pickupQty = (item['totalQuantityBagKg'] ?? 0).toDouble();
    final byvehicle = (item['pickupTotalQuantityBagKg'] ?? 0).toDouble();


    final color = _getColorFromType(colourType);
    final diff = _getDiff(index, pickupQty);

    return TableRow(
      children: [
        Container(height: 70, color: color),
        _tableCell(item['wasteTypeColour']),
        _tableCell(item['totalNoOfBags'].toString()),

        _tableCell("$pickupQty kg"),
       // _tableCell("$byvehicle kg"),
        Padding(
          padding: const EdgeInsets.only(
            top: 10,
            bottom: 10,
            left: 5,
            right: 5,
          ),
          child: TextFormField(
            controller: _receivedbagsControllers[index],
            style: TextStyle(fontSize: 11),
            onChanged:
                (_) => setState(() {
              // if (_receivedbagsControllers[index].text.isEmpty) {
              //   value_entered[index] = false;
              // }
              // else{value_entered[index]=true;}
            }),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(

              suffixStyle: const TextStyle(fontSize: 10),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(
            top: 10,
            bottom: 10,
            left: 5,
            right: 5,
          ),
          child: TextFormField(
            controller: _receivedQtyControllers[index],
            style: TextStyle(fontSize: 11),
            onChanged:
                (_) => setState(() {
              if (_receivedQtyControllers[index].text.isEmpty) {
                value_entered[index] = false;
              }
              else{value_entered[index]=true;}
            }),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: 'Kg',
              suffixStyle: const TextStyle(fontSize: 10),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _tableCell("${diff.toStringAsFixed(2)} kg"),

        Center(
          child: IconButton(
            onPressed: () {
              setState(() {
                print(value_entered[index]);
                if (_receivedQtyControllers[index].text.isEmpty) {
                  setState(() {
                    value_entered[index] = false;
                  });
                }
                value_entered[index] = !value_entered[index];
              });
            },
            icon: Icon(Icons.check_circle),
            color: value_entered[index] ? Colors.green : Colors.grey,
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
                          builder: (context) => VehicleListScreen(),
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
