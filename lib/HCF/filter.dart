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

          final Map<String, Map<String, int>> summary = {
            'Yellow': {'quantity': 0, 'bags': 0},
            'Red': {'quantity': 0, 'bags': 0},
            'Blue': {'quantity': 0, 'bags': 0},
            'White': {'quantity': 0, 'bags': 0},
          };

          for (final item in data) {
            final colorId = item['wastecolourId'];
            final colorName = wasteColorLookup[colorId] ?? 'Unknown';

            final quantity = (item['totalQuantityBagKg'] ?? 0) as num;
            final bags = (item['totalNoOfBags'] ?? 0) as num;

            if (summary.containsKey(colorName)) {
              summary[colorName]!['quantity'] =
                  (summary[colorName]!['quantity'] ?? 0) + quantity.toInt();
              summary[colorName]!['bags'] =
                  (summary[colorName]!['bags'] ?? 0) + bags.toInt();
            }
          }

          summaryData = summary.entries.map((entry) {
            return {
              'category': entry.key,
              'quantity': entry.value['quantity'],
              'bags': entry.value['bags'],
            };
          }).toList();

          print("Summary Data: $summaryData");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BioWasteDataScreen(1,summaryData),
            ),
          );
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

  // wastecolourId -> Color Name


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
