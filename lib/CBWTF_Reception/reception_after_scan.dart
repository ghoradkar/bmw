import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/CBWTF_Reception/reception_Scanner.dart';
import 'package:mpcb_bio_waste/CBWTF_Reception/vehicle_list.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../authentication/logout.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class ReceptionAfterScan extends StatefulWidget {
  final String barcode;

  final List<dynamic>rows;
  final List<TextEditingController>receivedQtyControllers;
  final List<bool>value_entered;
  const ReceptionAfterScan({required this.barcode,required this.rows,required this.receivedQtyControllers,required this.value_entered});

  @override
  State<ReceptionAfterScan> createState() => _ReceptionAfterScanState();
}

class _ReceptionAfterScanState extends State<ReceptionAfterScan> {
  List<dynamic> rows = [];
  bool load = true;
  bool save = false;
  List<TextEditingController> _receivedQtyControllers = [];
  List<bool> value_entered = [];

  double _getDiff(int index, double pickupQty) {
    final receivedText = _receivedQtyControllers[index].text;
    final received = double.tryParse(receivedText) ?? 0.0;
    return ( pickupQty-received);
  }

  Future<void> fetchBarcodeDetails(scannedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';

      final response = await http.get(
        Uri.parse('${baseurl}${SCAN_QR_CODE}${scannedData}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('${baseurl}${SCAN_QR_CODE}${scannedData}');
      print(response.body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          for(int i=0;i<data['data'].length;i++){
            rows.add(data['data'][i]);
            _receivedQtyControllers.add(TextEditingController(text: data['data'][i]['pickupTotalQuantityBagCbwtfKg'].toString()));
            value_entered.add(false);
          }
          load = false;
        });
      } else {
        if (response.statusCode == 401) {
          final authService = AuthService();
          authService.logout(context);
        }
      }
    } catch (e) {
      setState(() {
        load = false;
      });
    }
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
        (item['puckupQty'] ?? 0).toDouble();
        final pickupBags = item['pickupNoOfbag'] ?? 0;

        return {


          "hcfWasteId": item['hcfWasteId'],
          "hcfId": item['hcfId'],
          "vehicleCount": item['vehicleCount'],
          "hcfWasteQntyDetId": item['hcfWasteQntyDetId'],
          "hcfCode": item['hcfCode'],
          "cbmtfFacilityName": item['cbmtfFacilityName'],
          "barcodeNo": item['barcodeNo'],
          "nameOfHcf": item['nameOfHcf'],
        "totalNoOfBags": pickupBags,
        "totalQuantityBagKg": item['totalQuantityBagKg'],
        "hcfName": item['nameOfHcf'],
        "userId": userId,
          "wastecolourId": item['wastecolourId'],
          "wasteQtyId": item['wasteQtyId'],
          "colourType": item['colourType'],
        "receivedBag": pickupBags,
        "receivedQty": receivedQty,
        "pickupNoOfbag": pickupBags,
        "puckupQty": receivedQty,
        "differenceInQty": pickupQty - receivedQty,
          "hcfWasteVehicleAssignId": item['hcfWasteVehicleAssignId'],
        "pickupTotalQuantityBagKg": pickupQty,
        "diffrenceInBag": pickupBags - (item['receivedBag'] ?? 0),
        "differenceInQtyCbwtf":  pickupQty - receivedQty,
        "differenceInQtyCbwtfDisposal": 0,
          "assignDateCbwtf": item['assignDateCbwtf'],
          "assignDateCbwtfDisposal": nowUtc,
        "pickupTotalQuantityBagCbwtfKg":receivedQty,
        "pickupTotalQuantityBagCbwtfDisposalKg":0



        };
      });

      print(jsonEncode(body));

      final response = await http.post(
        Uri.parse('$baseurl$SAVE_RECEPTION_DATA$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body)
      );

      print('$baseurl$SAVE_WASTE_DISPOSAL$userId');
      print(response.body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
        showSuccessDialog(context);
      } else if (response.statusCode == 401) {
        AuthService().logout(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => save = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _receivedQtyControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  @override
  void initState() {
    super.initState();

    // Initialize rows
    rows = widget.rows;

    // Create controllers, copy existing values if present
    _receivedQtyControllers = List.generate(
      rows.length,
          (index) {
        final controller = TextEditingController();
        final value = widget.receivedQtyControllers.isNotEmpty
            ? widget.receivedQtyControllers[index].text
            : null;

        if (value != null && value.isNotEmpty) {
          controller.text = value;
        }
        return controller;
      },
    );

    // Initialize value_entered flags
    value_entered = List.generate(
      rows.length,
          (index) {
        final value = widget.value_entered.isNotEmpty
            ? widget.value_entered[index]
            : false;
        return value;
      },
    );

    print(rows);
    print(widget.barcode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // After widget is in the tree, safe to access ScaffoldMessenger / context
    if (rows.isEmpty) {
      fetchBarcodeDetails(widget.barcode);
    } else {
      bool found = false;
      for (int i = 0; i < rows.length; i++) {
        if (rows[i]['barcodeNo'] == widget.barcode) {
          found = true;
          break;
        }
      }

      if (found) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Barcode Already Scanned')),
          );
        });
        setState(() {
          load=false;});
      } else {
        fetchBarcodeDetails(widget.barcode);
      }
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
            showActions: true,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: IconButton(
                  onPressed: () async {

                    final scannedData = await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  ReceptionScanner(rows,_receivedQtyControllers,value_entered)
                      ),
                    );

                    if (scannedData != null) {
                      setState(() {
                        final alreadyExists = rows.any(
                              (item) => item['barcode'] == scannedData['barcode'],
                        );

                        if (!alreadyExists) {
                          fetchBarcodeDetails(scannedData);
                          // rows.add(scannedData);  // if you want to append it
                        }
                      });
                    }
                  },



                  icon: const Icon(Icons.document_scanner_outlined),
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
                                          } else {
                                            value_entered[i] = true;

                                             SaveWaste();
                                          }
                                        }

                                        // Trigger error message if any value is empty
                                        if (!isValid) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please fill all Received Quantity fields.',
                                              ),
                                            ),
                                          );
                                          return; // Exit early, do not proceed
                                        }
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
                          )],
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
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.5),

        6: FlexColumnWidth(1),
        7: FlexColumnWidth(1),
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
            "Barcode",
            "Qty by HCF",
            'Qty by Vehicle',
            'Received By CBWTF',

            "Difference in Qty",
            "",
          ]),
        ),
        for (int i = 0; i < rows.length; i++) _buildDataRow(rows[i], i),
      ],
    );
  }

  TableRow _buildDataRow(Map<String, dynamic> item, int index) {
    final barcode = item['barcodeNo'] ?? '--';
    final colourType = item['colourType'] ?? 'G';
    final pickupQty = (item['totalQuantityBagKg'] ?? 0).toDouble();
    final byvehicle = (item['puckupQty'] ?? 0).toDouble();


    final color = _getColorFromType(colourType);
    final diff = _getDiff(index, pickupQty);

    return TableRow(
      children: [
        Container(height: 70, color: color),
        _tableCell(barcode),
        _tableCell("$pickupQty kg"),
        _tableCell("$byvehicle kg"),

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
