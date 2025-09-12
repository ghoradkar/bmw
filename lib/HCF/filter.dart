import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/HCF/bio_waste_screen.dart';
import 'package:mpcb_bio_waste/HCF/bio_waste_table.dart';
import 'package:mpcb_bio_waste/network/offline.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import 'bio_waste_summary.dart';

class ViewDetails extends StatefulWidget {
  @override
  State<ViewDetails> createState() => _ViewDetailsState();
}

class _ViewDetailsState extends State<ViewDetails> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  DateTimeRange? _selectedRange;
  List<Map<String, dynamic>> summaryData = [];
  bool isLoading = true;
  bool isEdit = false;
  bool isLoadingColor=false;
  List<ColorCategory> colorCategories = [];
  ColorCategory? selectedColor;
  Map<int, String> wasteColorLookup = {};

  void _pickDateRange() async {
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedRange,
    );

    if (result != null) {
      setState(() {
        _selectedRange = result;
        fromDateController.text=DateFormat('dd/MM/yyyy').format(_selectedRange!.start);
        toDateController.text=DateFormat('dd/MM/yyyy').format(_selectedRange!.end);
      });
    }
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

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('Token');
      var userJson = prefs.getString('user');

      if (userJson == null || token == null) {
        print("Missing user or token in SharedPreferences");
        return;
      }

      Map<String, dynamic> user = jsonDecode(userJson);
      var userId = user['userId'];

      if (userId == null || fromDateController.text.isEmpty || toDateController.text.isEmpty) {
        print("userId or from/to date is null or empty");
        return;
      }

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final body = {
        "fromDate": fromDateController.text,
        "toDate": toDateController.text,
        "userId": userId,
      };

      print("Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('${baseurl}${FILTER}'),
        headers: headers,
        body: jsonEncode(body),
      );

      print("API URL: ${baseurl}${FILTER}");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'Success') {
          final List<dynamic> data = jsonResponse['data'];

          summaryData= buildSummaryData(data);


          print("✅ Final Summary Data: $summaryData");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BioWasteTableScreen(summaryData),
            ),
          );
          // final Map<String, Map<String, double>> grouped = {};
          //
          // for (final item in data) {
          //   final int? colorId = item['wastecolourId'];
          //   final int? hcfWasteId = item['hcfWasteId'];
          //   if (colorId == null || hcfWasteId == null) continue;
          //
          //   final String key = "$hcfWasteId-$colorId";
          //
          //   final double quantity = (item['totalQuantityBagKg'] ?? 0).toDouble();
          //   final double bags = (item['totalNoOfBags'] ?? 0).toDouble();
          //
          //   // ✅ Accumulate instead of overwriting
          //   if (!grouped.containsKey(key)) {
          //     grouped[key] = {'quantity': 0, 'bags': 0};
          //   }
          //
          //   grouped[key]!['quantity'] = (grouped[key]!['quantity'] ?? 0) + quantity;
          //   grouped[key]!['bags'] = (grouped[key]!['bags'] ?? 0) + bags;
          // }
          //
          //
          // // /// ✅ Collapse duplicates by unique (hcfWasteId, wastecolourId)
          // // final Map<String, Map<String, double>> grouped = {};
          // //
          // // for (final item in data) {
          // //   final int? colorId = item['wastecolourId'];
          // //   final int? hcfWasteId = item['hcfWasteId'];
          // //   if (colorId == null || hcfWasteId == null) continue;
          // //
          // //   final String key = "$hcfWasteId-$colorId";
          // //
          // //   final double quantity = (item['totalQuantityBagKg'] ?? 0).toDouble();
          // //   final double bags = (item['totalNoOfBags'] ?? 0).toDouble();
          // //
          // //   // overwrite or keep last entry (avoids double counting)
          // //   grouped[key] = {
          // //     'quantity': quantity,
          // //     'bags': bags,
          // //   };
          // // }
          // //
          // // /// ✅ Initialize summary (lookupDetIds from your color master)
          // // final Map<int, Map<String, double>> summary = {
          // //   239: {'quantity': 0, 'bags': 0}, // Yellow
          // //   240: {'quantity': 0, 'bags': 0}, // Red
          // //   241: {'quantity': 0, 'bags': 0}, // Blue
          // //   242: {'quantity': 0, 'bags': 0}, // White
          // // };
          // //
          // // /// ✅ Aggregate from grouped map
          // // grouped.forEach((key, values) {
          // //   final int colorId = int.parse(key.split("-")[1]);
          // //   if (summary.containsKey(colorId)) {
          // //     summary[colorId]!['quantity'] =
          // //         (summary[colorId]!['quantity'] ?? 0) + values['quantity']!;
          // //     summary[colorId]!['bags'] =
          // //         (summary[colorId]!['bags'] ?? 0) + values['bags']!;
          // //   }
          // // });
          // //
          // // /// ✅ Map lookup IDs to display names
          // // final Map<int, String> colorLabels = {
          // //   239: 'Yellow',
          // //   240: 'Red',
          // //   241: 'Blue',
          // //   242: 'White',
          // // };
          // //
          // // /// Build final summaryData in fixed order
          // // summaryData = [
          // //   {
          // //     'category': colorLabels[239],
          // //     'quantity': summary[239]!['quantity'],
          // //     'bags': summary[239]!['bags'],
          // //   },
          // //   {
          // //     'category': colorLabels[240],
          // //     'quantity': summary[240]!['quantity'],
          // //     'bags': summary[240]!['bags'],
          // //   },
          // //   {
          // //     'category': colorLabels[241],
          // //     'quantity': summary[241]!['quantity'],
          // //     'bags': summary[241]!['bags'],
          // //   },
          // //   {
          // //     'category': colorLabels[242],
          // //     'quantity': summary[242]!['quantity'],
          // //     'bags': summary[242]!['bags'],
          // //   },
          // // ];
          // //
          // // print("✅ Final Summary Data: $summaryData");
          //
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => BioWasteTableScreen(summaryData),
          //   ),
          // );
        } else {
          print("API returned failure: ${jsonResponse['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message']), backgroundColor: Colors.red),
          );
        }
      } else {
        print("Failed response: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error fetching bio waste summary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Build summary data that matches API "summaryData"
  List<Map<String, dynamic>> buildSummaryData(List<dynamic> data) {
    // per hcfWasteId + color → hold latest bags, sum qty
    final Map<String, Map<String, num>> grouped = {};

    for (final item in data) {
      final int? colorIdRaw = item['wastecolourId'] is num
          ? (item['wastecolourId'] as num).toInt()
          : null;
      final int? hcfWasteIdRaw =
      item['hcfWasteId'] is num ? (item['hcfWasteId'] as num).toInt() : null;
      if (colorIdRaw == null) continue;
      final int colorId = colorIdRaw;
      final int hcfWasteId = hcfWasteIdRaw ?? -1;

      final num bagsNum = item['totalNoOfBags'] ?? 0;
      final int bags =
      (bagsNum is int) ? bagsNum : (bagsNum as num).toInt();
      final double qty = (item['totalQuantityBagKg'] ?? 0).toDouble();

      final String key = "$hcfWasteId-$colorId";
      final g = grouped.putIfAbsent(key, () => {'bags': 0, 'qty': 0.0});

      // overwrite bags (so duplicates don't stack)
      g['bags'] = bags;
      // always accumulate quantity
      g['qty'] = (g['qty'] as double) + qty;
    }

    // final per-colour sums
    final Map<int, int> totalBagsPerColor = {};
    final Map<int, double> totalQtyPerColor = {};

    grouped.forEach((k, v) {
      final int color = int.parse(k.split("-")[1]);
      totalBagsPerColor[color] =
          (totalBagsPerColor[color] ?? 0) + (v['bags'] as num).toInt();
      totalQtyPerColor[color] =
          (totalQtyPerColor[color] ?? 0.0) + (v['qty'] as num).toDouble();
    });

    // fixed colour order
    final List<int> colorOrder = [239, 240, 241, 242];
    final Map<int, String> colorLabels = {
      239: 'Yellow',
      240: 'Red',
      241: 'Blue',
      242: 'White'
    };

    return colorOrder.map((colorId) {
      return {
        'category': colorLabels[colorId],
        'bags': totalBagsPerColor[colorId] ?? 0,
        'quantity': totalQtyPerColor[colorId] ?? 0.0,
      };
    }).toList();
  }



  final Map<String, Color> categoryColors = {
    'Yellow': Colors.yellow,
    'Red': Colors.red,
    'Blue': Colors.blue,
    'White': Colors.white,
  };




  @override
  void initState() {
    super.initState();
    GetCategoryList();


  }

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
                  scTitle: 'HCF Bio Waste Data',
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
                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 30),
                    decoration: BoxDecoration(
                      color: kWhiteColor,

                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(40),
                        topLeft: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            /// Form Box
                            Container(
                              decoration: BoxDecoration(color: kWhiteColor,
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  border: Border.all(color: Colors.grey.shade300)),

                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [


                                    /// Date fields
                                    Row(
                                      children: [
                                        Expanded(
                                          child:TextFormField(
                                            controller: fromDateController,
                                            onTap: _pickDateRange,
                                            style: TextStyle(fontSize: 12),

                                            decoration: InputDecoration(
                                              labelText: "From Date",
                                              labelStyle: TextStyle(fontSize: 12),

                                              prefixIcon: Icon(Icons.calendar_month,color: kPrimaryColor,),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.grey.shade400),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              focusedBorder:    OutlineInputBorder(
                                                borderSide: BorderSide(color:kPrimaryColor),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: toDateController,
                                            style: TextStyle(fontSize: 12),
                                            onTap: _pickDateRange,

                                            decoration: InputDecoration(
                                              labelText: "To Date",
                                              labelStyle: TextStyle(fontSize:12),
                                              prefixIcon: Icon(Icons.calendar_month,color: kPrimaryColor,),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.grey.shade400),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              focusedBorder:    OutlineInputBorder(
                                                borderSide: BorderSide(color:kPrimaryColor),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 16),

                                    /// Buttons
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
                                            text: 'Reset',
                                            onPressed: (){
                                              setState(() {
                                                toDateController.clear();
                                                fromDateController.clear();


                                              });
                                            },
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        SizedBox(
                                          width: responsiveWidth(150),
                                          child: AppButton(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5,
                                              horizontal: 15,
                                            ),
                                            text: 'Search',
                                            onPressed: () {
                                              setState(() {
                                                fromDateController.text.isEmpty ||toDateController.text.isEmpty?
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Please Select Dates'), backgroundColor: Colors.red),
                                                )  :
                                                fetchBioWasteSummary();

                                                // showSuccessDialog(context);

                                              });

                                            },
                                            color: Colors.deepOrange,
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
                      ),
                    ),
                  ))])), offlineChild: Offline()));
  }
}
