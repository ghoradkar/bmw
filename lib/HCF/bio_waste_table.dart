import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Global/app_button.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import 'bio_waste_summary.dart';

class BioWasteTableScreen extends StatefulWidget {
  List<Map<String, dynamic>> summarydata;
  BioWasteTableScreen(this.summarydata,{super.key});
  @override
  State<BioWasteTableScreen> createState() => _BioWasteTableScreenState();
}

class _BioWasteTableScreenState extends State<BioWasteTableScreen> {
  List<Map<String, dynamic>> summaryData = [];
  bool isLoading = true;
  bool isEdit = false;
  bool isLoadingColor=false;
  List<ColorCategory> colorCategories = [];
  ColorCategory? selectedColor;
  Map<int, String> wasteColorLookup = {}; // wastecolourId -> Color Name


  final Map<String, Color> categoryColors = {
    'Yellow': Colors.yellow,
    'Red': Colors.red,
    'Blue': Colors.blue,
    'White': Colors.white,
  };


  @override
  void initState() {
    super.initState();

   widget.summarydata.isEmpty? fetchBioWasteSummary():{
     setState(() {
       summaryData=widget.summarydata;
       isLoading=false;
     })
   };
    GetCategoryList();

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


  Future<void> fetchBioWasteSummary() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('Token');
    Map<String, dynamic> user = jsonDecode(prefs.getString('user')!);

    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      var date = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final response = await http.get(
        Uri.parse(
          '${baseurl}${GET_BIO_WASTE_DATA_FOR_HCF}date=$date&userId=${user['userId']}',
        ),
        headers: headers,
      );


      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];

        // Initialize grouped summary
        final Map<String, Map<String, int>> summary = {
          'Yellow': {'quantity': 0, 'bags': 0},
          'Red': {'quantity': 0, 'bags': 0},
          'Blue': {'quantity': 0, 'bags': 0},
          'White': {'quantity': 0, 'bags': 0},
        };

        for (final item in data) {
          final colorId = item['wastecolourId'];
          final colorName = wasteColorLookup[colorId];

          // Skip unknown colors
          if (colorName == null || !summary.containsKey(colorName)) continue;

          final quantity = (item['totalQuantityBagKg'] ?? 0) as num;
          final bags = (item['totalNoOfBags'] ?? 0) as num;

          summary[colorName]!['quantity'] =
              (summary[colorName]!['quantity'] ?? 0) + quantity.toInt();
          summary[colorName]!['bags'] =
              (summary[colorName]!['bags'] ?? 0) + bags.toInt();
        }

        // Convert to list
        summaryData = summary.entries.map((entry) {
          return {
            'category': entry.key,
            'quantity': entry.value['quantity'],
            'bags': entry.value['bags'],
          };
        }).toList();
      } else {
        summaryData = [];
      }
    } catch (e) {
      print("Error: $e");
      summaryData = [];
    }

    setState(() => isLoading = false);
  }


  Map<String, Color> wasteColorMap = {
    'Y': Colors.yellow,
    'R': Colors.red,
    'B': Colors.blue,
    'W': Colors.white,
  };


  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      body:
          isLoading || isLoadingColor
              ? const Center(child: CircularProgressIndicator())
              : summaryData.isEmpty||summaryData==null?Datanotfound():Padding(
                padding: const EdgeInsets.all(13.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Table(
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
                                  "Total Quantity (kg/Annum)",
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
                          for (int i = 0; i < summaryData.length; i++)
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
                                              categoryColors[summaryData[i]['category']] ??
                                              Colors.grey,
                                          shape: BoxShape.rectangle,
                                          border: Border.all(
                                            color:
                                                summaryData[i]['category'] ==
                                                        'White'
                                                    ? Colors.black
                                                    : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        summaryData[i]['category'],
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
                                    enabled: isEdit,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    initialValue:
                                        summaryData[i]['quantity'].toString(),
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
                                      summaryData[i]['quantity'] =
                                          int.tryParse(val) ?? 0;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TextFormField(
                                    enabled: isEdit,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    initialValue:
                                        summaryData[i]['bags'].toString(),
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
                                      summaryData[i]['bags'] =
                                          int.tryParse(val) ?? 0;
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: responsiveHeight(100)),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //   children: [
                      //    !isEdit? SizedBox(
                      //       width: responsiveWidth(150),
                      //       child: AppButton(
                      //         padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      //         text: 'Edit',
                      //         onPressed: () {
                      //           setState(() {
                      //             isEdit=!isEdit;
                      //           });
                      //           // TODO: Handle edit logic
                      //         },
                      //         color: Colors.deepOrange,
                      //       ),
                      //     ):
                      //
                      //     SizedBox(
                      //       width: responsiveWidth(150),
                      //       child: AppButton(
                      //         padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                      //         text: 'Cancel',
                      //         onPressed: () {
                      //           setState(() {
                      //             isEdit=false;
                      //           });
                      //
                      //         },
                      //         color: Colors.grey.shade400,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
    );
  }
}
