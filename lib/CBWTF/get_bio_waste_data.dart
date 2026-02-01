import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/CBWTF/apiservice.dart';
import 'package:mpcb_bio_waste/CBWTF/view_detail.dart';

import 'package:mpcb_bio_waste/network/offline.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/app_textfield.dart';
import '../Global/constant.dart';
import '../Global/images.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../authentication/logout.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';

class GetBioWasteData extends StatefulWidget {
  List<dynamic> filteredList;
  GetBioWasteData(this.filteredList, {super.key});
  @override
  State<GetBioWasteData> createState() => _GetBioWasteDataState();
}

class _GetBioWasteDataState extends State<GetBioWasteData> {
  List<bool>? isSelectedList = [];
  bool selectAll = false;
  TextEditingController vehicle = new TextEditingController();
  List<dynamic> selectedHcfs = [];
  final _formKey = GlobalKey<FormState>();
  List filteredList = [];
  bool isEditMode = false;

  Future<void> fetchHCFPolygon() async {
    print('list');
    print(widget.filteredList);
    final hcfIds = widget.filteredList
        .map((e) => e['hcfId'].toString())
        .toSet() // remove duplicates
        .join(',');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await prefs.getString('Token') ?? '';
      var userId = await prefs.getString('UserId');

      final response = await http.get(
        Uri.parse('${baseurl}${CBWTF_MAP_MULTIPLE_HCF}$hcfIds'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        // body: body,
      );
      print('${baseurl}${CBWTF_MAP_MULTIPLE_HCF}$hcfIds');

      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          filteredList = data['data'];
          isSelectedList = List.filled(filteredList!.length, false);
        });
        print('filteredlist');
        print(filteredList.length);
      } else {
        print('API error: ${response.statusCode}');
        if (response.statusCode == 401) {
          final authService = AuthService();
          authService.logout(context);
        }
      }
    } catch (e) {
      print('Error fetching HCFs: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchHCFPolygon();
  }

  void resetForm() {
    setState(() {
      // Clear vehicle text
      vehicle.clear();

      // Uncheck all checkboxes
      for (int i = 0; i < isSelectedList!.length; i++) {
        isSelectedList![i] = false;
      }

      // Clear selected HCF list
      selectedHcfs.clear();

      // Unselect the selectAll toggle
      selectAll = false;

      // If using Form
      //_formKey.currentState?.reset();
    });
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;

      for (int i = 0; i < isSelectedList!.length; i++) {
        isSelectedList![i] = selectAll;
      }

      // Update selectedHcfs list
      selectedHcfs.clear();
      if (selectAll) {
        selectedHcfs.addAll(
          filteredList,
        ); // assuming widget.hcfList is your full list
      }
    });
  }

  void toggleSelection(int index, bool? value) {
    setState(() {
      isSelectedList![index] = value ?? false;

      final hcf = filteredList[index];
      if (value == true) {
        if (!selectedHcfs.contains(hcf)) {
          selectedHcfs.add(hcf);
        }
      } else {
        selectedHcfs.removeWhere(
          (element) => element['surveyId'] == hcf['surveyId'],
        );
      }

      selectAll = isSelectedList!.every((e) => e);
    });

    print(selectedHcfs.length);
    print(selectedHcfs);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return StreamProvider<NetworkStatus>(
      create:
          (context) => NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
          body: Stack(
            children: [
              /// Custom Gradient AppBar
              mAppBar(
                scTitle: 'CBWTF Bio Waste Data',
                centerTile: false,
                showLeading: true,
                showActions: true,
                onLeadingIconClick: () => Navigator.pop(context),
                actions: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isEditMode = true;
                      });
                    },
                    icon: Icon(Icons.edit),
                  ),
                ],
              ),

              /// Body with tabs
              Positioned.fill(
                top: responsiveHeight(110),
                bottom: responsiveHeight(
                  0,
                ), // offset to appear below custom app bar
                child: Container(
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    // scrollDirection: Axis.horizontal,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: responsiveHeight(20)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            child: AppTextfield(
                              controller: vehicle,
                              prefixIcon: Icons.fire_truck_outlined,
                              obscureText: false,
                              hintText: 'Assign Vehicle',
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.toString().trim().isEmpty) {
                                  return 'Enter vehicle number';
                                }

                                // // Optional: Add pattern match for format like MH12AB1234
                                final pattern =
                                    r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$';
                                final regExp = RegExp(pattern);

                                if (!regExp.hasMatch(
                                  value.toUpperCase().replaceAll(' ', ''),
                                )) {
                                  return 'Enter valid vehicle number(e.g., MH12AB1234)';
                                }

                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectAll,
                                  onChanged: toggleSelectAll,
                                ),
                                const Text("Select All"),
                              ],
                            ),
                          ),

                          // Table Header
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            color: Colors.transparent,
                            child: Table(
                              border: TableBorder.symmetric(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                                inside: BorderSide(color: Colors.grey.shade300),
                              ),
                              columnWidths: const {
                                0: FixedColumnWidth(30),
                                1: FixedColumnWidth(50),
                                2: FixedColumnWidth(90),
                                3: FixedColumnWidth(40),
                                4: FixedColumnWidth(40),
                                5: FixedColumnWidth(40),
                                6: FixedColumnWidth(40),
                              },

                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        kPrimaryColor,
                                        kPrimaryDarkColor,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  children: const [
                                    _HeaderCell('Sr. No.'),
                                    _HeaderCell('Date'),
                                    _HeaderCell('HCF Name'),
                                    _HeaderCell('Total\nno. of Bags'),
                                    _HeaderCell('Quantity\n(in Kgs)'),
                                    _HeaderCell('Action'),
                                    _HeaderCell('View'),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Table Body
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Table(
                                border: TableBorder.symmetric(
                                  inside: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                columnWidths: const {
                                  0: FixedColumnWidth(30),
                                  1: FixedColumnWidth(60),
                                  2: FixedColumnWidth(80),
                                  3: FixedColumnWidth(40),
                                  4: FixedColumnWidth(40),
                                  5: FixedColumnWidth(40),
                                  6: FixedColumnWidth(40),
                                },

                                children: List.generate(filteredList!.length, (
                                  index,
                                ) {
                                  final hcf = filteredList![index];
                                  var date = DateFormat('dd/MM/yyyy').format(
                                    DateTime.parse(
                                      hcf['wasteQntyDateStr'].toString(),
                                    ),
                                  );

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color:
                                          hcf['vehicleNo'].isEmpty
                                              ? isEditMode
                                                  ? Colors.grey
                                                  : Colors.white
                                              : isEditMode
                                              ? Colors.white
                                              : Colors.green,
                                    ),
                                    children: [
                                      _DataCell('${index + 1}'),
                                      _DataCell(date),
                                      _DataCell(hcf['hcfName'] ?? ''),
                                      _DataCell(
                                        '${hcf['totalNoOfBags'] ?? ''}',
                                      ),
                                      _DataCell(
                                        '${hcf['totalQuantityBagKg'] ?? ''}',
                                        isBold: true,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                        child: Checkbox(
                                          value:
                                              hcf['vehicleNo'].isEmpty
                                                  ? isEditMode
                                                      ? false
                                                      : isSelectedList![index]
                                                  : isEditMode
                                                  ? isSelectedList![index]
                                                  : false,
                                          onChanged: (val) {
                                            setState(() {
                                              isSelectedList![index] =
                                                  val ?? false;
                                              toggleSelection(index, val);
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => HcfDetailsScreen(
                                                    hcf['hcfWasteId'],
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.remove_red_eye_outlined,
                                        ),
                                      ),

                                      // IconButton(onPressed: (){}, icon: Icon(Icons.remove_red_eye_outlined,color: kPrimaryColor,))
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// 🔽 Fixed buttons (don’t scroll)
          bottomNavigationBar: SafeArea(
            // ✅ prevents going under navigation bar
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: AppButton(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      text: isEditMode ? 'Edit' : 'Save',
                      onPressed: () async {
                        // final vehicleNumber = vehicle.text.trim();
                        //
                        // if (!_formKey.currentState!.validate()) return;
                        //
                        // if (selectedHcfs.isEmpty) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content: Text("Please select at least one HCF"),
                        //       backgroundColor: Colors.red,
                        //     ),
                        //   );
                        //   return;
                        // }

                        // var body = await ApiService.buildWastePayloadList(
                        //   inputList: selectedHcfs,
                        //   vehicleNo: vehicleNumber,
                        // );

                      //   if (body.isNotEmpty) {
                      //     var value = await ApiService.AssignVehicle(
                      //       context,
                      //       body,
                      //     );
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       SnackBar(content: Text('${value['message']}')),
                      //     );
                      //     if (value['status'] == 'Succes') {
                      //       setState(() {
                      //         isEditMode = false;
                      //         fetchHCFPolygon();
                      //         showSuccess(this.context);
                      //       });
                      //       resetForm();
                      //     }
                      //   } else {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text('Failed')),
                      //     );
                      //   }
                       },
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      text: isEditMode ? 'Reset' : 'Delete',
                      onPressed: () {
                        if (isEditMode) {
                          setState(() => isEditMode = false);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        //              SizedBox(height: responsiveHeight(50)),
        //              Row(
        //                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //                children: [
        //                  SizedBox(
        //                    width: responsiveWidth(150),
        //                    child: AppButton(
        //                      padding: const EdgeInsets.symmetric(
        //                        vertical: 5,
        //                        horizontal: 15,
        //                      ),
        //                      text: isEditMode?'Edit':'Save',
        //                      onPressed: () async{
        //                        final vehicleNumber = vehicle.text.trim();
        //
        // // First, basic validations
        //                        if (!_formKey.currentState!.validate()) {
        //                          return;
        //                        }
        //
        //                        if (selectedHcfs.isEmpty) {
        //                          ScaffoldMessenger.of(context).showSnackBar(
        //                            const SnackBar(
        //                              content: Text("Please select at least one HCF"),
        //                              backgroundColor: Colors.red,
        //                            ),
        //                          );
        //                          return;
        //                        }
        //
        // // Debugging prints
        //                        print("Vehicle Number: $vehicleNumber");
        //                        print("Selected HCF count: ${selectedHcfs.length}");
        //
        // // Build request payload
        //                        Map<String, dynamic> value;
        //                        var body = await ApiService.buildWastePayloadList(
        //                          inputList: selectedHcfs,
        //                          vehicleNo: vehicleNumber,
        //                        );
        //
        //                        print(body);
        //
        // // If payload is not empty, make API call
        //                        if (body.isNotEmpty) {
        //                          value = await ApiService.AssignVehicle(context, body);
        //
        //                          print(value['data']);
        //
        //                          ScaffoldMessenger.of(context).showSnackBar(
        //                            SnackBar(content: Text('${value['message']}')),
        //                          );
        //
        //                          if (value['status'] == 'Succes') {
        //                            // ✅ Remove assigned HCFs from the main list
        //                            setState(() {
        //                              // widget.filteredList.removeWhere(
        //                              //       (hcf) => selectedHcfs.contains(hcf),
        //                              // );
        //                              isEditMode=false;
        //                              fetchHCFPolygon();
        //                              showSuccess(this.context);
        //
        //                              // reset selection
        //                            });
        //
        //                            resetForm(); // clear form after successful assignment
        //                          }
        //                        } else {
        //                          ScaffoldMessenger.of(context).showSnackBar(
        //                            const SnackBar(content: Text('Failed')),
        //                          );
        //                        }
        //
        //
        //
        //                      },
        //                      color: Colors.deepOrange,
        //                    ),
        //                  ),
        //                  SizedBox(
        //                    width: responsiveWidth(150),
        //                    child: AppButton(
        //                      padding: const EdgeInsets.symmetric(
        //                        vertical: 5,
        //                        horizontal: 15,
        //                      ),
        //                      text:isEditMode?'Reset': 'Delete',
        //                      onPressed: () => {
        //                        isEditMode?setState(() {
        //                          isEditMode=false;
        //                        }):{ Navigator.pop(context),},
        //
        //                       },
        //                      color: Colors.grey.shade400,
        //                    ),
        //                  ),
        //                ],
        //              ),
        //              SizedBox(height: responsiveHeight(50)),
        //            ],
        //          ),
        //        ),
        offlineChild: Offline(),
      ),
    );
  }
}

void showSuccess(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(success),
              const SizedBox(height: 24),
              const Text(
                "Vehicle Assigned Successfully.",
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
                    Navigator.pop(context);

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
            ],
          ),
        ),
      );
    },
  );
}

// Header cell widget
class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Data cell widget
class _DataCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const _DataCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 8,
        ),
      ),
    );
  }
}
