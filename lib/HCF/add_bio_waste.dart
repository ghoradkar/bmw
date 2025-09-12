
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:mpcb_bio_waste/Global/images.dart';
import 'package:mpcb_bio_waste/Global/size_config.dart';
import 'package:mpcb_bio_waste/HCF/table.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/app_textfield.dart';
import '../Global/url.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';
import 'barcodeImage.dart';
import 'bio_waste_summary.dart';
import 'bio_waste_table.dart';

class AddBioWasteDataTab extends StatefulWidget {
  const AddBioWasteDataTab({super.key});

  @override
  State<AddBioWasteDataTab> createState() => _AddBioWasteDataTabState();
}

class _AddBioWasteDataTabState extends State<AddBioWasteDataTab> {
  final List<String> categories = ['Yellow', 'Red', 'White', 'Blue'];
  final List<int> bagOptions = List.generate(20, (i) => i + 1);
  List<Map<String, dynamic>> selectedWasteEntries = [];
  Key dropdownKey = UniqueKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _onAddToBarcodeList({
    required int hcfWasteId,
    required int hcfWasteQntyDetId,
    required int wasteQtyId,
  }) {
    selectedWasteEntries.add({
      "hcfWasteId": hcfWasteId,
      "hcfWasteQntyDetId": hcfWasteQntyDetId,
      "wasteQtyId": wasteQtyId,
    });
  }




  String? selectedCategory;
  int? selectedBags;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool saved = false;

  bool isLoadingColor=false;

  List<Map<String, dynamic>> tableData = [];
//  List<Map<String, dynamic>> tableData = [];
  bool isLoading = false;
  bool isLoadingbarcode = false;
  List<ColorCategory> colorCategories = [];
  ColorCategory? selectedColor;
  List<Map<String, dynamic>> existingData = [];


  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    GetCategoryList();

  }


    Future<void> saveBioWasteLocally() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Load existing saved data
      String? existingJson = prefs.getString('tableData');

      if (existingJson != null) {
        List decoded = jsonDecode(existingJson);
        existingData = decoded
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      // Add only non-duplicate entries based on color + quantity
      for (var newItem in tableData) {
        bool isDuplicate = existingData.any((entry) =>
        entry['color'] == newItem['color'] &&
            entry['quantity'].toString().trim() == newItem['quantity'].toString().trim());

        if (!isDuplicate) {
          existingData.add(newItem);
        } else {
          print("Duplicate entry skipped: ${newItem['color']} with quantity ${newItem['quantity']}");
        }
      }

      // Save updated data back to prefs
      await prefs.setString('tableData', jsonEncode(existingData));
      print('tableData');
      print(tableData);


      _resetForm();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BioWasteSummaryTable(tableData),
        ),
      );
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
          colorCategories =
              data.map((item) => ColorCategory.fromJson(item)).toList();
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

  void _addBagsToTable() {
    setState(() {
      saved=false;

    });
    if (selectedColor != null && selectedBags != null) {
      for (int i = 0; i < selectedBags!; i++) {

        tableData.add({
          'id':selectedColor!.id,
          'category': selectedColor!.name,
          'quantity': '',
          'Date':DateTime.now().toString().substring(0,10),
          'Time':DateTime.now().toString().substring(11,19),
          'color':selectedColor!.name,
          'bags':selectedBags
              //=='Yellow'?Colors.yellow:selectedColor!.name=='Blue'?Colors.blue:selectedColor!.name=='Red'?Colors.red:Colors.white
              
        });
      }
      setState(() {
        selectedBags=null;
      //  saveBioWasteLocally();

        _resetForm();


      });
    }
  }
  Color? getColorFromCode(String code) {
    switch (code.toUpperCase()) {
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


  void _resetForm() {
    setState(() {
      selectedColor=null;
      selectedCategory = null;
      selectedBags = null;
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();

    });
  }

  void _removeRow(int index) {
    setState(() {
      tableData.removeAt(index);
    });
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get formattedDateTime {
    if (selectedDate == null || selectedTime == null) return '';
    final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate!);
    final formattedTime = formatTime(selectedTime!);
    return '$formattedDate    |    $formattedTime';
  }

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
            leadingWidget: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            showLeading: true,

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
    child:  SingleChildScrollView(child:Column(
    children: [
    SizedBox(height: responsiveHeight(20)),


          /// Form Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              children: [
                /// Category & Bags Row
                Row(
                  children: [
                    /// Category Dropdown

                    Expanded(
                      child: DropdownButtonFormField<ColorCategory>(
                        value: selectedColor,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        decoration: const InputDecoration(
                          labelText: "Category",
                          labelStyle: TextStyle(fontSize: 10, color: Colors.grey),
                          prefixIcon: Icon(Icons.menu, color: kPrimaryColor),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        items: colorCategories.map((colorCat) {
                          final Color? color = getColorFromCode(colorCat.code);

                          return DropdownMenuItem<ColorCategory>(
                            value: colorCat,
                            child: Row(
                              children: [
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    color: color ?? Colors.grey,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: color==Colors.white?Colors.grey:Colors.transparent)
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  colorCat.name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedColor = val;
                            print(selectedColor);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// Bags Dropdown
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: dropdownKey,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        value: selectedBags,
                        decoration: const InputDecoration(
                          labelText: "No. of Bags",
                          labelStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.shopping_bag,
                            color: kPrimaryColor,
                          ),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        items:
                            bagOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text("$e"),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedBags = val;

                          });
                          _addBagsToTable();

    setState(() {
    selectedBags = null;
    dropdownKey = UniqueKey();
    });




                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Date & Time Picker
               Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Date & Time",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formattedDateTime,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),


                const SizedBox(height: 16),


              ],
            ),
          ),

          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(
              color: Colors.grey.shade300,
              borderRadius:  BorderRadius.only(topRight: Radius.circular(10),
              topLeft: Radius.circular(10)),
            ),

            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  borderRadius:const BorderRadius.only(topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),

                  gradient: LinearGradient(
                    colors: [Color(0xFF00B4DB), Color(0xFF0099CC)],
                  ),
                ),
                children: const [
                  _TableHeaderCell("Bag No."),
                        _TableHeaderCell("Category"),
                        _TableHeaderCell("Weight (kg)"),
                        _TableHeaderCell("Action"),
                ],
              ),

              // Data Rows
              for (int i = 0; i < tableData.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? Colors.white : Colors.grey.shade50,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text("${i + 1}",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12),),
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
                              tableData[i]['color']=='Yellow'?Colors.yellow:tableData[i]['color']=='Blue'?Colors.blue:tableData[i]['color']=='Red'?Colors.red:Colors.white,
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color:
                                tableData[i]['category'] == 'White'
                                    ? Colors.black
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(tableData[i]['category'],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12),),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        enabled: saved?false:true,
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12),
                        initialValue:
                        tableData[i]['quantity'] == 0
                            ? ''
                            : tableData[i]['quantity'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          isDense: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            const BorderSide(color: Colors.blue),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            const BorderSide(color: Colors.grey),
                          ),
                        ),
                        onChanged: (val) {
                          tableData[i]['quantity'] =
                              double.tryParse(val) ?? 0;

                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8),
                      child:IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeRow(i),
                      ),
                    ),
                  ],
                ),
            ],
          ),



          /// Bottom Buttons
      /// Reset & Add Buttons
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
              onPressed: () {
                _resetForm();
                tableData.clear();
                existingData.clear();


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
              text: 'Add',
              onPressed: () {
                tableData.isNotEmpty || existingData.isNotEmpty?

                {saveBioWasteLocally()}:
                    { ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please Add waste'), backgroundColor: Colors.red),
                    )}

                ;},
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),

          // isLoading?CircularProgressIndicator(color: kPrimaryColor,):
          // saved==false?Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     SizedBox(
          //       width: responsiveWidth(150),
          //       child: AppButton(
          //         padding: const EdgeInsets.symmetric(
          //           vertical: 5,
          //           horizontal: 15,
          //         ),
          //         text: 'Save',
          //         onPressed: () {
          //           setState(() {
          //             tableData.isNotEmpty?{
          //             saved = true,
          //             print(tableData),
          //             SaveBioWaste(),}:{
          //               ScaffoldMessenger.of(context).showSnackBar(
          //                 const SnackBar(content: Text('Please Add Waste')),
          //               ),
          //             };
          //
          //           });
          //         },
          //         color: Colors.deepOrange,
          //       ),
          //     ),
          //     SizedBox(
          //       width: responsiveWidth(150),
          //       child: AppButton(
          //         padding: const EdgeInsets.symmetric(
          //           vertical: 5,
          //           horizontal: 15,
          //         ),
          //         text: 'Cancel',
          //         onPressed: () => {
          //           _resetForm(),
          //           tableData.clear(),
          //
          //         },
          //         color: Colors.grey.shade400,
          //       ),
          //     ),
          //   ],
          // ):SizedBox(),
        ],
      ),
    ),
    )
        )])),
    offlineChild: Offline()));
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
                      Navigator.pop(context);
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

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),

    );
  }
}
