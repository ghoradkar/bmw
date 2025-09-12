import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/vehicle_user/assign_hcf.dart';
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
import 'barcode_scanner_screen.dart';

class AfterScanScreen extends StatefulWidget {
  final String barcode;
  final List<dynamic>rows;
  final List<TextEditingController>receivedQtyControllers;
  final List<bool>value_entered;

  final Map<String, dynamic> detail;

  const AfterScanScreen({required this.barcode, required this.rows,required this.receivedQtyControllers,required this.value_entered, required this.detail});

  @override
  State<AfterScanScreen> createState() => _AfterScanScreenState();
}

class _AfterScanScreenState extends State<AfterScanScreen> {
  List<dynamic> rows = [];
  bool load = true;
  bool save = false;
  List<TextEditingController> receivedQtyControllers = [];
  List<bool> value_entered = [];

  @override
  void initState() {
    super.initState();

    // Initialize rows
    rows = widget.rows;

    // Create controllers, copy existing values if present
    receivedQtyControllers = List.generate(
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
  Future<void> fetchBarcodeDetails(barcode) async {

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';

      final response = await http.get(
        Uri.parse('${baseurl}${GET_QR_DATA}${barcode}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('${baseurl}${GET_QR_DATA}${barcode}');
      print(response.body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
        //  rows=data['data'];
          for(int i=0;i<data['data'].length;i++){
            rows.add(data['data'][i]);
            receivedQtyControllers.add(TextEditingController(text:data['data'][i]['pickupTotalQuantityBagKg'].toString()));
            value_entered.add(false);
          }

          // receivedQtyControllers = List.generate(
          //   rows.length,
          //   (_) => TextEditingController(),
          // );
          // value_entered = List.generate(rows.length, (_) => false);
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
            double.tryParse(receivedQtyControllers[i].text) ?? 0.0;
        final pickupQty =
            (item['pickupTotalQuantityBagCbwtfKg'] ?? 0).toDouble();
        final pickupBags = item['pickupNoOfbag'] ?? 0;

        return {
          "hcfWasteVehicleAssignId": item['hcfWasteVehicleAssignId'],
          "hcfWasteQntyDetId":item["hcfWasteQntyDetId"],
          "hcfWasteQntyId": item["wasteQtyId"],
          "hcfWasteId":item['hcfWasteId'],
          "totalNoOfBags": item['totalNoOfBags'] ?? 0,
          "totalQuantityBagKg": item['totalQuantityBagKg'] ?? 0,
          "pickupTotalQuantityBagCbwtfKg":pickupQty,
          "vehicleNo": userId,
          "assignDate": item['assignDateCbwtf'],
          "pickupNoOfBags": pickupBags,
          "pickupTotalQuantityBagKg": receivedQty,
          "pickupDate": nowUtc,
          "differenceInQty": receivedQty - pickupQty,
          "diffrenceInBag": pickupBags - (item['receivedBag'] ?? 0),
          "receivedBag": pickupBags,
          "receivedQty": receivedQty,
          "userId": userId,
          "status": 1,
          "createdBy": userId,
          "createdDate": nowUtc,
        };
      });
      print(rows.length);
      print(jsonEncode(body));

      final response = await http.post(
        Uri.parse('$baseurl$SAVE_WASTE$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('$baseurl$SAVE_WASTE$username');
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

  double _getDiff(int index, double pickupQty) {
    final receivedText = receivedQtyControllers[index].text;
    final received = double.tryParse(receivedText) ?? 0.0;
    return ( pickupQty-received);
  }

  @override
  void dispose() {
    for (var controller in receivedQtyControllers) {
      controller.dispose();
    }
    super.dispose();
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
          mAppBar(
            onLeadingIconClick: () => Navigator.pop(context),
            scTitle: 'Bio Waste Data Details',
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
                        builder: (context) =>  BarcodeScannerScreen(widget.detail,rows,receivedQtyControllers,value_entered),
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
          Positioned.fill(
            top: responsiveHeight(110),
            bottom: responsiveHeight(0),
            child: Container(
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
                          ..._buildHcfInfoBox(),
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
                                          i < receivedQtyControllers.length;
                                          i++
                                        ) {
                                          final text =
                                              receivedQtyControllers[i].text
                                                  .trim();

                                          if (text.isEmpty) {
                                            // Mark that this row does NOT have a value
                                            value_entered[i] = false;
                                            isValid = false;
                                          } else {
                                            value_entered[i] = true;
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

                                        // All values are filled, call save method
                                        showConfirmation(context);
                                       // SaveWaste();
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

  List<Widget> _buildHcfInfoBox() {
    return [
      Container(
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 0),

        //height: 120,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        decoration: BoxDecoration(
          color: Color.fromRGBO(239, 253, 255, 1),

          borderRadius: BorderRadius.all(Radius.circular(10)),
          border: Border.all(color: Colors.grey.shade300),
        ),

        child: Column(
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
                  TextSpan(text: widget.detail['name'] ?? 'NA'),
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
                        TextSpan(text: widget.detail['date'] ?? 'NA'),
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
                        TextSpan(text: widget.detail['hcfCode'] ?? 'NA'),
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
    ];
  }

  Widget _buildTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      columnWidths: const {
        0: FlexColumnWidth(0.15),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
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
            "Quantity Received",
            "Difference",
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
    final color = _getColorFromType(colourType);
    final diff = _getDiff(index, pickupQty);

    return TableRow(
      children: [
        Container(height: 55, color: color),
        _tableCell(barcode),
        _tableCell("$pickupQty kg"),
        Padding(
          padding: const EdgeInsets.all(6),
          child: TextFormField(
            controller: receivedQtyControllers[index],
            onChanged:
                (_) => setState(() {
                  if (receivedQtyControllers[index].text.isEmpty) {
                    value_entered[index] = false;
                  }
                }),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: 'Kg',
              suffixStyle: const TextStyle(fontSize: 11),
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
                if (receivedQtyControllers[index].text.isEmpty) {
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
                fontSize: 11,
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
      case 'R':
        return Colors.red;
      case 'Y':
        return Colors.yellow;
      case 'B':
        return Colors.blue;
      case 'W':
        return Colors.white;
      case 'G':
        return Colors.green;
      default:
        return Colors.grey.shade300;
    }
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                Image.asset(success),
                const SizedBox(height: 24),
                const Text(
                  "Bio Waste Data\nadded successfully.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: responsiveWidth(180),
                  child: AppButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 15,
                    ),
                    text: 'Ok',
                    onPressed: () {
                      setState(() {
                        rows.clear();
                        widget.rows.clear();
                        print(rows.length);
                      });

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignedHCFScreen(),
                        ),
                        (Route<dynamic> route) => false,
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
  void showConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                Image.asset(success),
                const SizedBox(height: 24),
                const Text(
                  "Do You Want To Save ?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children:[ SizedBox(
                  width: responsiveWidth(125),
                  child: AppButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 15,
                    ),
                    text: 'Yes',
                    onPressed: () {
                      SaveWaste();
                      // Navigator.pushAndRemoveUntil(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => AssignedHCFScreen(),
                      //   ),
                      //       (Route<dynamic> route) => false,
                      // );
                    },
                    color: Colors.deepOrange,
                  ),
                ),
                SizedBox(
                  width: responsiveWidth(125),
                  child: AppButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 15,
                    ),
                    text: 'Cancel',
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigator.pushAndRemoveUntil(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => AssignedHCFScreen(),
                      //   ),
                      //       (Route<dynamic> route) => false,
                      // );
                    },
                    color: Colors.grey,
                  ),
                ),])
              ],
            ),
          ),
        );
      },
    );}
}
