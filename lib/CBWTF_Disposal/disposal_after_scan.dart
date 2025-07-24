import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/CBWTF_Disposal/waste_received_byvehicle.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../authentication/logout.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class DisposalAfterScan extends StatefulWidget {
  final String barcode;
  final int wasteId;
  DisposalAfterScan(this.barcode,this.wasteId,{super.key});
  @override
  _DisposalAfterScanState createState() => _DisposalAfterScanState();
}

class _DisposalAfterScanState extends State<DisposalAfterScan> {
  List<dynamic> rows = [];
  bool load = true;
  bool save = false;
  List<TextEditingController> _receivedQtyControllers = [];
  List<bool> value_entered = [];
  @override
  void initState() {
    super.initState();
    widget.wasteId==0?fetchBarcodeDetails():fetchWasteDetails();
  }

  Future<void> fetchBarcodeDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';

      final response = await http.get(
        Uri.parse('${baseurl}${GET_BARCODE_DATA}${widget.barcode}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('${baseurl}${GET_BARCODE_DATA}${widget.barcode}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          rows = data['data'];
          _receivedQtyControllers = List.generate(
            rows.length,
                (_) => TextEditingController(),
          );
          value_entered = List.generate(rows.length, (_) => false);
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
  Future<void> fetchWasteDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';

      final response = await http.get(
        Uri.parse('${baseurl}${GET_BIO_WASTE_DETAILS}${widget.wasteId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('${baseurl}${GET_BARCODE_DATA}${widget.wasteId}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          rows = data['data'];
          _receivedQtyControllers = List.generate(
            rows.length,
                (_) => TextEditingController(),
          );
          value_entered = List.generate(rows.length, (_) => false);
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
        (item['pickupTotalQuantityBagCbwtfKg'] ?? 0).toDouble();
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
          "wasteQntyDate": item['wasteQntyDate'],
          "vehicleAssignDate": item['vehicleAssignDate'],
          "wasteQntyDateStr": item['wasteQntyDateStr'],
          "vehicleAssignDateStr": item['vehicleAssignDateStr'],
          "totalNoOfBags": item['totalNoOfBags'],
          "totalQuantityBagKg": item['totalQuantityBagKg'],
          "vehicleUserId": item['vehicleUserId'],
          "vehicleNo": item['vehicleNo'],
          "hcfName": item['hcfName'],
          "userId": userId,
          "chassisNo": item['chassisNo'],
          "vehicleUserName": item['vehicleUserName'],
          "wasteTypeColour": item['wasteTypeColour'],
          "wastecolourId": item['wastecolourId'],
          "wasteQtyId": item['wasteQtyId'],
          "colourType": item['colourType'],
          "receivedBag": pickupBags,
          "receivedQty": receivedQty,
          "pickupNoOfbag": pickupBags,
          "puckupQty": pickupQty,
          "differenceInQty": pickupQty - receivedQty,
          "hcfWasteVehicleAssignId": item['hcfWasteVehicleAssignId'],
          "pickupTotalQuantityBagKg": pickupQty,
          "diffrenceInBag": pickupBags - (item['receivedBag'] ?? 0),
          "differenceInQtyCbwtf": pickupQty - receivedQty,
          "differenceInQtyCbwtfDisposal": pickupQty - receivedQty,
          "assignDateCbwtf": item['assignDateCbwtf'],
          "assignDateCbwtfDisposal": nowUtc,
          "pickupTotalQuantityBagCbwtfKg": pickupQty,
          "pickupTotalQuantityBagCbwtfDisposalKg": receivedQty,
          "hcfWasteQntyId": item['hcfWasteQntyId'],
          "bagNo": item['bagNo'],
          "pickupDate": nowUtc,
          "wasteList": item['wasteList'] ?? [],
          "status": 1,
          "createdBy": userId,
          "createdDate": nowUtc,
        };
      });

      print(jsonEncode(body));

      final response = await http.post(
        Uri.parse('$baseurl$SAVE_WASTE_DISPOSAL$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
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

  double _getDiff(int index, double pickupQty) {
    final receivedText = _receivedQtyControllers[index].text;
    final received = double.tryParse(receivedText) ?? 0.0;
    return (received - pickupQty);
  }

  @override
  void dispose() {
    for (var controller in _receivedQtyControllers) {
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
            scTitle: 'View Details',
            centerTile: false,
            showLeading: true,
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
                  : rows.isEmpty||rows!=null?Datanotfound():Column(
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
                      : Row(
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
                ],
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
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1.5),
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
            "Disposed By CBWTF",
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
    final byvehicle = (item['pickupTotalQuantityBagKg'] ?? 0).toDouble();
    final bycbwtf=(item['pickupTotalQuantityBagCbwtfDisposalKg'] ?? 0).toDouble();

    final color = _getColorFromType(colourType);
    final diff = _getDiff(index, pickupQty);

    return TableRow(
      children: [
        Container(height: 70, color: color),
        _tableCell(barcode),
        _tableCell("$pickupQty kg"),
        _tableCell("$byvehicle kg"),
        _tableCell("$bycbwtf kg"),
        Padding(
          padding: const EdgeInsets.only(top: 10,bottom: 10,left: 5,right: 5),
          child: TextFormField(
            controller: _receivedQtyControllers[index],
            style: TextStyle(fontSize: 11),
            onChanged:
                (_) => setState(() {
              if (_receivedQtyControllers[index].text.isEmpty) {
                value_entered[index] = false;
              }
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
        Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
        builder: (context) => WasteReceivedByvehicle(),
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
}
