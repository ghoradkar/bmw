import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
import '../Global/constant.dart';
import '../Global/dataNotFound.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';
import 'barcodeImage.dart';
import 'hcf_model.dart';

class BioWasteDetailTableScreen extends StatefulWidget {
  final Map<String,dynamic> data;
  BioWasteDetailTableScreen(this.data,{super.key});


  @override
  State<BioWasteDetailTableScreen> createState() => _BioWasteDetailTableScreenState();
}

class _BioWasteDetailTableScreenState extends State<BioWasteDetailTableScreen> {

  bool isLoadingbarcode = false;
  List<dynamic>? wasteList=[];
  bool isLoading=false;
  List<Map<String, dynamic>> selectedWasteEntries = [];
  bool isLoadingColor=false;
  Map<int, String> wasteColorLookup = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<HcfWasteModel> wasteData = [];

  @override
  void initState() {
    super.initState();
    GetCategoryList();
   fetchBioWasteSummary();
  }
  Future<void> GetCategoryList() async {
    setState(() {
      isLoadingColor=true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('Token');
    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final url = Uri.parse(
        '${baseurl}${CATEGORY_LOOKUP}',
      );

      final response = await http.get(
        url,
        headers: headers,
      );

      print(response.body);

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        setState(() {

          wasteColorLookup = {
            for (var item in data)
              item['lookupDetId']: item['lookupDetDescEn']
          };
        });
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
      isLoadingColor = false;
    });
  }

  Color _getColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'Y':
        return Colors.yellow;
      case 'R':
        return Colors.red;
      case 'B':
        return Colors.blue;
      case 'W':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }
  Future<void> fetchBioWasteSummary() async {
    setState(() => isLoading = true);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // var token = prefs.getString('Token');
    // Map<String, dynamic> user = jsonDecode(prefs.getString('user')!);
    //
    try {
      final int hcfWasteId = widget.data['hcfWasteId'];
       wasteList = widget.data['wasteList'] ?? [];
      print(wasteList);
      for (var waste in wasteList!) {
        final hcfWasteQntyId = waste["hcfWasteQntyId"];
        final List<dynamic> wasteDetList = waste["wasteDetList"] ?? [];

        for (var det in wasteDetList) {
          final hcfWasteQntyDetId = det["hcfWasteQntyDetId"];

          selectedWasteEntries.add({
            "hcfWasteId": hcfWasteId,
            "hcfWasteQntyId": hcfWasteQntyId,
            "hcfWasteQntyDetId": hcfWasteQntyDetId,
          });
        }
      }
      print(selectedWasteEntries);
    //   final headers = {
    //     'Content-Type': 'application/json; charset=UTF-8',
    //     'Accept': 'application/json ; charset=UTF-8',
    //     'Authorization': 'Bearer $token',
    //   };
    //
    //   var date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    //   final response = await http.get(
    //     Uri.parse(
    //       '${baseurl}${GET_BIO_WASTE_DATA_FOR_HCF}date=$date&userId=${user['userId']}',
    //     ),
    //     headers: headers,
    //   );
    //
    //
    //   if (response.statusCode == 200) {
    //     final jsonResponse = jsonDecode(response.body);
    //     final List<dynamic> data = jsonResponse['data'] ?? [];
    //
    //
    //
    //     wasteList = data.map((e) => Map<String, dynamic>.from(e)).toList();
    //   } else {
    //    wasteList = [];
    //   }
    } catch (e) {
      print("Error: $e");

    }

    setState(() => isLoading = false);
  }
  final Map<String, Color> categoryColors = {
    'Yellow': Colors.yellow,
    'Red': Colors.red,
    'Blue': Colors.blue,
    'White': Colors.white,
  };


  Future<void> generateBarcode(Map<String, dynamic> selectedEntry) async {
    setState(() {
      isLoadingbarcode = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('Token');

    final body = {
      "hcfWasteId": selectedEntry["hcfWasteId"],
      "hcfWasteQntyDetId": selectedEntry["hcfWasteQntyDetId"],
      "wasteQtyId": selectedEntry["hcfWasteQntyId"]
    };

    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${baseurl}${GENERATE_BARCODE}'),
        headers: headers,
        body: jsonEncode(body),
      );
      print(jsonEncode(body));

      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.bodyBytes;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BarcodeImageScreen(imageBytes: imageBytes),
          ),
        );
      } else {
        print(response.statusCode);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication Error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error generating barcode')),
      );
      print('Error: $e');
    }

    setState(() {
      isLoadingbarcode = false;
    });
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.lightBlue,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: const [
          Expanded(child: Center(child: Text('Bag No.', style: TextStyle(color: Colors.white)))),
          Expanded(child: Center(child: Text('Category', style: TextStyle(color: Colors.white)))),
          Expanded(child: Center(child: Text('Weight in kg', style: TextStyle(color: Colors.white)))),
          Expanded(child: Center(child: Text('Print Barcode', style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, Map<String, dynamic> entry) {
    final colorId = entry['lookupDetIdCategory'];
    final colorName = wasteColorLookup[colorId];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(child: Center(child: Text('${index + 1}'))),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color:categoryColors[colorName] ??
                        Colors.grey,
                    border: Border.all(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 5),
                Text(colorName!),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 60,
                child: TextField(
                  controller: TextEditingController(text: entry['totalQuantityBagKg'].toString()),
                  onChanged: (value) {
                    setState(() {
                      entry['totalQuantityBagKg'] = double.tryParse(value) ?? 0;
                    });
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ),
          ),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.print),
              onPressed: isLoadingbarcode
                  ? null
                  : () {
                generateBarcode(entry);
              },
            ),
          ),
        ],
      ),
    );
  }
  Future<void> sendWasteData() async {
    wasteData = selectedWasteEntries.map((item) {
      return HcfWasteModel(
        hcfWasteId: item['hcfWasteId'],
        hcfWasteQntyDetId: item['hcfWasteQntyDetId'],
        hcfWasteQntyId: item['hcfWasteQntyId'],
      );
    }).where((e) =>
    e.hcfWasteQntyDetId != null && e.hcfWasteQntyId != null).toList();

  print(wasteData.length);


  final body = wasteData.map((e) => e.toJson()).toList();
    print('send');
    print(wasteData.length);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('Token');
    Map<String, dynamic> user = jsonDecode(prefs.getString('user')!);

    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };


      final response = await http.post(
        Uri.parse('${baseurl}${MULTIPLE_BARCODE}'),
        headers: headers,

        body: jsonEncode(body),
      );
      print(jsonEncode(body));

      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.bodyBytes as Uint8List;
        print(response.body);

        // Navigate to a preview screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BarcodeImageScreen(imageBytes: imageBytes),
          ),
        );
        // success logic
        print('Data submitted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data submitted successfully')));
      } else {

        // error logic
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed')));
      }
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching barcodes')),
      );
      print('Error fetching barcodes: $e');
    }}

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
              showActions: true,
              actions: [IconButton(onPressed: (){
                sendWasteData();

              }, icon: Icon(Icons.document_scanner_outlined))]

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
    child:  isLoading || isLoadingColor
            ? const Center(child: CircularProgressIndicator())
            : wasteList!.isEmpty||wasteList==null?Datanotfound():Column(
          children: [

            const SizedBox(height: 4),
            Expanded(
              child: Table(
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
                          "Bag. No",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10
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
                              fontSize: 10
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Weight In KG",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                              fontSize: 10
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: EdgeInsets.all(8),
                      //   child: Text(
                      //     "No. of Bags",
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Print Barcode",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                              fontSize: 10
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (int i = 0; i < wasteList!.length; i++)

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
                                  categoryColors[wasteColorLookup[wasteList![i]['lookupDetIdCategory']]] ??
                                      Colors.grey,
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color:
                                    wasteColorLookup[wasteList![i]['lookupDetIdCategory']]=='White'
                                        ? Colors.black
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                wasteColorLookup[wasteList![i]['lookupDetIdCategory']]!,
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

                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            initialValue:
                            wasteList![i]['totalQuantityBagKg'].toString(),
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
                              wasteList![i]['totalQuantityBagKg'] =
                                  double.tryParse(val) ?? 0;
                            },
                          ),
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.all(8),
                        //   child: TextFormField(
                        //
                        //     style: const TextStyle(
                        //       fontWeight: FontWeight.bold,
                        //       fontSize: 12,
                        //     ),
                        //     initialValue:
                        //     wasteList![i]['totalQuantityBagKg'].toString(),
                        //     keyboardType: TextInputType.number,
                        //     decoration: InputDecoration(
                        //       contentPadding:
                        //       const EdgeInsets.symmetric(
                        //         horizontal: 10,
                        //         vertical: 10,
                        //       ),
                        //       isDense: true,
                        //       enabledBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: const BorderSide(
                        //           color: Colors.grey,
                        //         ),
                        //       ),
                        //       focusedBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: const BorderSide(
                        //           color: Colors.blue,
                        //         ),
                        //       ),
                        //       disabledBorder: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //         borderSide: const BorderSide(
                        //           color: Colors.grey,
                        //         ),
                        //       ),
                        //     ),
                        //     onChanged: (val) {
                        //       wasteList![i]['bags'] =
                        //           int.tryParse(val) ?? 0;
                        //     },
                        //   ),
                        // ),
                        IconButton(
                            icon: const Icon(Icons.print),
                            onPressed: isLoadingbarcode
                                ? null
                                : () {
                              generateBarcode(selectedWasteEntries[i]);
                            },
                          ),



                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )])),
    offlineChild: Offline()));
  }
}
