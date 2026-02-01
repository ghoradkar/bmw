import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_dropdown.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class ViewDetailsAfterScan extends StatefulWidget {
  @override
  State<ViewDetailsAfterScan> createState() => _ViewDetailsAfterScanState();
}

class _ViewDetailsAfterScanState extends State<ViewDetailsAfterScan> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  bool isLoading=false;
  bool isLoadingColor=true;
  List hcfList=[];
  String? selectedhcf;
  List <Map<String,dynamic>>vehicleList=[];
  Map<String,dynamic>? selectedVehicle;
  DateTimeRange? _selectedRange;
  List<dynamic> rows = [];
  String? hcfname;
  String? hcfcode;
  bool _isLoading=false;
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




  Future<void> fetchHCFData() async {
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
      final fromDate = formatDate(_selectedRange!.start.toString());
      final toDate = formatDate(_selectedRange!.end.toString());
      final body = {

          "userId": userId,
          "scheduleFromDate": fromDate,
          "scheduleToDate": toDate,
          "vehicleNo": selectedVehicle!['vehicleNo']

      };



      print("Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('${baseurl}${FILTER_RECEPTION_DATA}'),
        headers: headers,
        body: jsonEncode(body),
      );

      print("API URL: ${baseurl}${FILTER_RECEPTION_DATA}");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'Success') {
          rows = jsonResponse['data'];
          setState(() {
            rows;
            print(rows);
           rows==[]||rows.isEmpty?datanotfound=true:datanotfound=false;
          });



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
      print('Error fetching HCF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }

    setState(() {
      isLoading = false;
    });
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


  Future<void> fetchVehicle() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final response = await http.get(
        Uri.parse('${baseurl}${GET_VEHICLE_USERS}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        vehicleList = List<Map<String, dynamic>>.from(res['data'] ?? []);
      }
    } catch (_) {
      _showError("Failed to fetch vehicles");
    }

    setState(() => _isLoading = false);
  }  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void initState() {
    super.initState();

    fetchVehicle();

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
    scTitle: t.translate('view_details'),
    centerTile: false,
    showLeading: true,
            showActions: true,
            actions: [
              Padding(padding:EdgeInsets.all(10) ,child:IconButton(onPressed: (){}, icon: Icon(Icons.file_download_outlined,color: kWhiteColor,)))]

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
          child: isLoading || _isLoading?Center(child: CircularProgressIndicator(color: kPrimaryColor,),) :datanotfound?
          SizedBox(
              height: 600,width: 500,
              child:Datanotfound()):Column(
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
                      /// HCF name
                      // DropdownButtonFormField<String>(
                      //
                      //   icon: const Icon(Icons.keyboard_arrow_down, color:kPrimaryColor),
                      //   decoration: InputDecoration(
                      //     label: RichText(
                      //       text: const TextSpan(
                      //         text: 'Name Of HCF',
                      //         style: TextStyle(fontSize: 12, color: Colors.black),
                      //         children: [
                      //
                      //         ],
                      //       ),
                      //     ),
                      //
                      //     hintText: 'Select',
                      //     hintStyle: TextStyle(color: kBlackColor.withOpacity(0.2)),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //       borderSide: BorderSide(color: kBlackColor.withOpacity(0.3)),
                      //     ),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //   ),
                      //   value:selectedhcf,
                      //   items: hcfList.map((item) {
                      //     return DropdownMenuItem<String>(
                      //
                      //
                      //       value: item['hcfId'].toString(),
                      //       child: Text(
                      //         item['hcfName'],
                      //         style: const TextStyle(fontSize: 10),
                      //       ),
                      //     );
                      //   }).toList(),
                      //     onChanged: (val) {
                      //       setState(() {
                      //         selectedhcf = val;
                      //
                      //         // Safely get the selected item from the list
                      //         var result = hcfList.firstWhere(
                      //               (element) => element['hcfId'].toString() == selectedhcf,
                      //           orElse: () => {}, // return empty map if not found
                      //         );
                      //         hcfname=result['hcfName'];
                      //         hcfcode=result['hcfCode'];
                      //
                      //
                      //         print('Selected HCF Details: $result');
                      //       });
                      //     }
                      //
                      // ),
                      InkWell(
                          onTap: () {
                            _openVehicleBottomSheet(context,t);
                          },
                          child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.grey.shade200,
                                ),

                                child:validatedApiDropdown(
                                  color: Colors.grey.shade500,
                                  hint: t.translate('assign_vehicle'),
                                  value: selectedVehicle,
                                  items: vehicleList,
                                  displayKey: "vehicleNo",
                                  icon: Icons.fire_truck_outlined,
                                  errorText: "Please select Vehicle",
                                  onChanged: (v) {}, // handled via bottom sheet
                                ),
                              )),
                        ),

                      SizedBox(height: 16),

                      /// Date fields

                      /// Date fields
                      Row(
                        children: [
                          Expanded(
                            child:TextFormField(
                              controller: fromDateController,
                              onTap: _pickDateRange,
                              style: TextStyle(fontSize: 12),

                              decoration: InputDecoration(
                                labelText: t.translate('from_date'),
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
                                labelText: t.translate('to_date'),
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
                              text: t.translate('reset'),
                              onPressed: (){
                                setState(() {
                                  toDateController.clear();
                                  fromDateController.clear();
                                  selectedhcf=null;
                                  selectedVehicle!.clear();

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
                              text:t.translate('search'),
                              onPressed: () {
                                setState(() {

                                  fetchHCFData();

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

              /// HCF Details
              rows.isNotEmpty?Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   // Text(hcfname!, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${t.translate('vehicle_number')} : ${selectedVehicle!['vehicleNo']}"),
                  ],
                ),
              ):SizedBox(),

              SizedBox(height: 16),

              /// Table
              rows.isNotEmpty?Table(
                columnWidths: const {
                  0: FixedColumnWidth(30),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2),
                  5: FlexColumnWidth(2),
                //  6: FixedColumnWidth(30),
                },
                border: TableBorder.all(color: Colors.grey.shade300,
                borderRadius: BorderRadius.all(Radius.circular(10))),
                children: [
                  /// Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey,borderRadius: BorderRadius.only(topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
                    children:  [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(t.translate('srno'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(t.translate('cbwtf_pickedup_Date'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(t.translate('hcf_code'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(t.translate('hcf_name'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(t.translate('total_weight'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 10)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(t.translate('vehicle_number'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 10)),
                      ),
                      
                    ],
                  ),

                  /// Rows
                  for (var row in rows)

                    TableRow(
                      decoration: BoxDecoration(borderRadius:BorderRadius.all(Radius.circular(10))),
                      children: [
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('${rows.indexOf(row) + 1}', style: TextStyle(fontSize: 9))),
                        Padding(padding: EdgeInsets.all(8), child: Text(row['wasteQntyDateStr']??'',style: TextStyle(fontSize: 11,))),
                        Padding(padding: EdgeInsets.all(8), child: Text(row['hcfCode'].toString()??'0',style: TextStyle(fontSize: 11,))),
                        Padding(padding: EdgeInsets.all(8), child: Text(row['hcfName'].toString()??'0',style: TextStyle(fontSize: 11,))),
                        Padding(padding: EdgeInsets.all(8), child: Text(row['totalQuantityBagKg'].toString()??'0',style: TextStyle(fontSize: 11,))),
                        Padding(padding: EdgeInsets.all(8), child: Text(row['vehicleNo'].toString()??'0',style: TextStyle(fontSize: 11,))),
                        //Icon(Icons.check_circle, color: Colors.green,size: 20,),
                      ],
                    ),
                ],
              ):SizedBox(),
            ],
          ),
        ),
      ),
    ))])), offlineChild: Offline()));
  }
  void _openVehicleBottomSheet(BuildContext context,t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // IMPORTANT
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6, // control height
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Drag handle
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

          Text(
            t.translate('select_vehicle')      ,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),
              const Divider(),

              // ✅ ONLY ListView scrolls
              Expanded(
                child: ListView.separated(
                  itemCount: vehicleList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final vehicle = vehicleList[index];

                    return ListTile(
                      leading: const Icon(Icons.fire_truck_outlined),
                      title: Text(vehicle["vehicleNo"] ?? "-"),
                      trailing: selectedVehicle == vehicle
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedVehicle = vehicle;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
