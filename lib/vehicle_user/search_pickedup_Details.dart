import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class SearchPickedupDetails extends StatefulWidget {
  @override
  State<SearchPickedupDetails> createState() => _SearchPickedupDetailsState();
}

class _SearchPickedupDetailsState extends State<SearchPickedupDetails> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  bool isLoading=false;
  bool isLoadingColor=true;
  List hcfList=[];
  String? selectedhcf;
  DateTimeRange? _selectedRange;
  List<dynamic> rows = [];
  String? hcfname;
  String? hcfcode;
  bool datanotfound=false;

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return '';

    try {
      // Parse the input date
      DateTime parsedDate = DateTime.parse(date);

      // Return in YYYY-MM-DD format
      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Invalid date format: $date');
      return '';
    }
  }




  Future<void> fetchAssignedVehicle() async {
    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('Token');
      var userJson = prefs.getString('user');

      if (userJson == null || token == null) {
        print("Missing user or token in SharedPreferences");
        setState(() => isLoading = false);
        return;
      }

      Map<String, dynamic> user = jsonDecode(userJson);
      var userId = user['userName'];
      print(user);

      if (userId == null) {
        print("UserId is null");
        setState(() => isLoading = false);
        return;
      }

      final fromDate = formatDate(_selectedRange!.start.toString());
      final toDate = formatDate(_selectedRange!.end.toString());

      if (fromDate.isEmpty || toDate.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid From and To date')),
        );
        setState(() => isLoading = false);
        return;
      }

      final body = {



          "scheduleFromDate": fromDate,
          "scheduleToDate":toDate,
          "userName": userId

      };

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${baseurl}${SEARCH_ASSIGNED_VEHICLELIST}'),
        headers: headers,
        body: jsonEncode(body),
      );
      print(body);
      print(response.body)
;
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'Succes') {
          rows = jsonResponse['data'];
          print(rows);
          setState(() {
            datanotfound = rows.isEmpty;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message']), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => isLoading = false);
  }

  String reformatDate(String inputDate) {
    try {
      // Validate input with RegExp for dd-MM-yyyy
      final regex = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
      final match = regex.firstMatch(inputDate);

      if (match == null) {
        throw FormatException('Invalid date format');
      }

      final day = match.group(1)!;
      final month = match.group(2)!;
      final year = match.group(3)!;

      // Optional: further validation for correct day/month ranges
      final intDay = int.parse(day);
      final intMonth = int.parse(month);

      if (intDay < 1 || intDay > 31) throw FormatException('Invalid day');
      if (intMonth < 1 || intMonth > 12) throw FormatException('Invalid month');

      // Convert to dd/MM/yyyy
      return '$day/$month/$year';
    } catch (e) {
      return 'Invalid Date'; // fallback
    }
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


  @override
  void initState() {
    super.initState();


  }
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();
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
                        scTitle:  t.translate('search_vehicle_details'),
                        centerTile: false,
                        showLeading: true,
                        // showActions: true,
                        // actions: [
                        //   Padding(padding:EdgeInsets.all(10) ,child:IconButton(onPressed: (){}, icon: Icon(Icons.file_download_outlined,color: kWhiteColor,)))]

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
                                child: isLoading?Center(child: CircularProgressIndicator(color: kPrimaryColor,),) :
                               Column(
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
                                                      labelText:  t.translate('from_date'),
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
                                                      labelText:  t.translate('to_date'),
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
                                                    text:  t.translate('reset'),
                                                    onPressed: (){
                                                      setState(() {
                                                        toDateController.clear();
                                                        fromDateController.clear();
                                                        selectedhcf=null;

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
                                                    text:  t.translate('search'),
                                                    onPressed: () {
                                                      setState(() {

                                                        fetchAssignedVehicle();

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

                                    SizedBox(height: 16),





                                    /// Table
                                    rows.isEmpty
                                        ?  SizedBox(
                                        height: 600,width: 500,
                                        child:Datanotfound()):LayoutBuilder(
                                      builder: (context, constraints) {


                                        return Table(
                                          columnWidths: {
                                            0: FixedColumnWidth(40),  // Sr. No.
                                            1: FixedColumnWidth(70),  // Date
                                            2: FixedColumnWidth(100),  // HCF Code
                                            3: FixedColumnWidth(50), // HCF Name
                                            4: FixedColumnWidth(50),  // No. of Bags
                                             // Vehicle Number
                                          },
                                          border: TableBorder.all(color: Colors.grey.shade300,borderRadius: BorderRadius.all(Radius.circular(10))),
                                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                          children: [
                                            // Header
                                            TableRow(

                                              decoration: BoxDecoration(color: kPrimaryColor,
                                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10),
                                                      topRight: Radius.circular(10))),
                                              children:  [
                                                Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text( t.translate('srno'),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 10)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text( t.translate('date'),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 10)),
                                                ),
                                                // Padding(
                                                //   padding: EdgeInsets.all(5),
                                                //   child: Text("HCF Code",
                                                //       textAlign: TextAlign.center,
                                                //       style: TextStyle(
                                                //           color: Colors.white,
                                                //           fontWeight: FontWeight.bold,
                                                //           fontSize: 10)),
                                                // ),
                                                Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text( t.translate('hcf_name'),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 10)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text( t.translate('total_bags'),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 10)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text( t.translate('total_waste'),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 10)),
                                                ),
                                                // Padding(
                                                //   padding: EdgeInsets.all(5),
                                                //   child: Text("Vehicle Number",
                                                //       textAlign: TextAlign.center,
                                                //       style: TextStyle(
                                                //           color: Colors.white,
                                                //           fontWeight: FontWeight.bold,
                                                //           fontSize: 10)),
                                                // ),
                                              ],
                                            ),

                                            // Rows
                                            for (int i = 0; i < rows.length; i++)
                                              TableRow(
                                                // decoration: BoxDecoration(
                                                //     color: i % 2 == 0 ? Colors.grey.shade100 : Colors.transparent),
                                                children: [
                                                  Padding(
                                                      padding: EdgeInsets.all(8),
                                                      child: Text('${i + 1}', style: TextStyle(fontSize: 9))),
                                                  Padding(
                                                      padding: EdgeInsets.all(8),
                                                      child: Text(rows[i]['vehicleAssignDate'] ?? '-',
                                                          style: TextStyle(fontSize: 9))),
                                                  // Padding(
                                                  //     padding: EdgeInsets.all(8),
                                                  //     child: Text(rows[i]['hcfCode']?.toString() ?? '0',
                                                  //         style: TextStyle(fontSize: 9))),
                                                  Padding(
                                                      padding: EdgeInsets.all(8),
                                                      child: Text(rows[i]['nameOfHcf']?.toString() ?? '-',
                                                          style: TextStyle(fontSize: 9))),
                                                  Padding(
                                                      padding: EdgeInsets.all(8),
                                                      child: Text(rows[i]['totalNoOfBags']?.toString() ?? '0',
                                                          style: TextStyle(fontSize: 9))),
                                                  Padding(
                                                      padding: EdgeInsets.all(8),
                                                      child: Text(rows[i]['totalQuantityBagKg']?.toString() ?? '0',
                                                          style: TextStyle(fontSize: 9))),
                                                  // Padding(
                                                  //     padding: EdgeInsets.all(8),
                                                  //     child: Text(rows[i]['vehicleNo']?.toString() ?? '-',
                                                  //         style: TextStyle(fontSize: 9))),
                                                ],
                                              ),
                                          ],
                                        );
                                      },
                                    )
                                        // : Center(child: Text("No data found"))


                                  ],
                                )
                              ),
                            ),
                          ))])), offlineChild: Offline()));
  }
}
