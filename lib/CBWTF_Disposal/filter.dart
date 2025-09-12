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

class Filter_disposal extends StatefulWidget {
  Filter_disposal({super.key});

  @override
  State<Filter_disposal> createState() => _Filter_disposalState();
}

class _Filter_disposalState extends State<Filter_disposal> {
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
  bool data_not_found = false;
  TextEditingController DateController = TextEditingController();

  double _getDiff(int index, double pickupQty) {
    final receivedText = _receivedQtyControllers[index].text;
    final received = double.tryParse(receivedText) ?? 0.0;
    return (pickupQty - received);
  }

  @override
  void initState() {
    super.initState();
    //fetchTableData();
  }

  DateTime? pickedDate;

  _selectDate(BuildContext context) async {
    pickedDate = await showDatePicker(
      context: context,
      initialDatePickerMode: DatePickerMode.day,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(3000),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // override MaterialApp ThemeData
            colorScheme: ColorScheme.light(
              primary: Color.fromRGBO(
                21,
                144,
                207,
                1,
              ), //header and selced day background color
              onPrimary: Colors.white, // titles and
              onSurface: Colors.black, // Month days , years
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                // ok , cancel    buttons
              ),
            ),
          ),
          child: child!,
        );
        // if (pickedDate != null) {
        //   setState(() {
        //     _selectedDate = pickedDate; // Store the selected date
        //   });
        // }
        //  here you can return  a child
      },
    );
    if (pickedDate != null) {
      setState(() {
        DateController.text = DateFormat('dd/MM/yyyy').format(pickedDate!);
       // final today = DateTime.now().toString().substring(0, 10);
      });
    }
  }

  Future<void> fetchTableData(date) async {
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
          '${baseurl}${GET_DISPOSAL_DATA}fromDate=$date&toDate=$date&userId=$UserId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        //  body: jsonEncode(widget.formattedList.first)
      );
      print(
        '${baseurl}${GET_DISPOSAL_DATA}fromDate=$date&toDate=$date&userId=$UserId',
      );
      print(response.body);

      if (response.statusCode == 200) {
        Map<String, dynamic> value = json.decode(response.body);

        setState(() {
          List<dynamic> data = value['data'] ?? [];

          rows = data;
          _receivedQtyControllers = List.generate(
            rows.length,
            (_) => TextEditingController(),
          );
          value_entered = List.generate(rows.length, (_) => false);
          rows.isEmpty ? data_not_found = true : data_not_found = false;

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
      create: (context) => NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
          drawer: AppDrawer(),
          key: _scaffoldKey,
          body: Stack(
            children: [
              /// Custom Gradient AppBar
              mAppBar(
                showLeading: true,
                onLeadingIconClick: () => Navigator.pop(context),
                scTitle: 'Search Disposal Data',
                centerTile: false,
              ),

              /// Body with rounded container
              Positioned.fill(
                top: 100, // leave space for custom app bar
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                    ),
                  ),

                  /// Make the whole body scrollable
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(height: 16),

                        /// Filter Box
                        Container(
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [

                                /// Date field
                                TextFormField(
                                  controller: DateController,
                                  readOnly: true,
                                  onTap: () {
                                    _selectDate(context);
                                  },
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    labelText: "Select Date",
                                    labelStyle: const TextStyle(fontSize: 12),
                                    prefixIcon: Icon(
                                      Icons.calendar_month,
                                      color: kPrimaryColor,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: kPrimaryColor),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                /// Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      width: responsiveWidth(150),
                                      child: AppButton(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 15),
                                        text: 'Reset',
                                        onPressed: () {
                                          setState(() {
                                            DateController.clear();
                                          });
                                        },
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    SizedBox(
                                      width: responsiveWidth(150),
                                      child: AppButton(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 15),
                                        text: 'Search',
                                        onPressed: () {
                                          setState(() {
                                            fetchTableData(pickedDate.toString().substring(0,10));
                                            // fetchHCFData();
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

                        const SizedBox(height: 16),

                        /// Results
                        if (load)
                          Center(
                            child: CircularProgressIndicator(color: kPrimaryColor),
                          )
                        else if (data_not_found)
                          SizedBox(
                            height: 700,
                              child:Datanotfound())
                        else
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              rows.isEmpty?SizedBox():
                              SingleChildScrollView(child:_buildTable(),)
                              ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        offlineChild: Offline(),
      ),
    );
  }


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
        // 5: FlexColumnWidth(0.9),
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
}
