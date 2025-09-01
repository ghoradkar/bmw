import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/vehicle_user/bii_waste_detail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart'; // for Future

class AssignedHCFScreen extends StatefulWidget {
  @override
  _AssignedHCFScreenState createState() => _AssignedHCFScreenState();
}

class _AssignedHCFScreenState extends State<AssignedHCFScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tableData = [];

  @override
  void initState() {
    super.initState();
    fetchAssignedHCFData();
  }
  Future<void> fetchAssignedHCFData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final username = prefs.getString('Username');

      final response = await http.get(
        Uri.parse('${baseurl}${GET_BIO_WASTE_DATA}$username'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },);
      print('${baseurl}${GET_BIO_WASTE_DATA}$username');
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String,dynamic> value = jsonDecode(response.body);
        List<dynamic>data=value['data'];

        setState(() {
          _tableData = data.map((e) =>
          { 'hcfCode':e['hcfCode'],
            'wasteId': e['hcfWasteId'],
            'date': e['wasteQntyDate'],
            'name': e['nameOfHcf'],
            'bags': e['totalNoOfBags'],
            'waste': e["totalQuantityBagKg"],
          }).toList();
          _isLoading = false;
        });
      } else {
        // handle error
        setState(() => _isLoading = false);
      }
    }
    catch (e) {
      print('Error fetching HCFs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching HCFs: $e'), backgroundColor: Colors.red),
      );
    }
    }

  // Future<void> fetchAssignedHCFData() async {
  //   try {
  //     // Replace this delay and list with your actual API call using http.get()
  //     await Future.delayed(const Duration(seconds: 2));
  //     final responseData = [
  //       {
  //         "date": "15/06/2025",
  //         "name": "Manipal Hospital",
  //         "bags": 60,
  //         "waste": 600
  //       },
  //       {
  //         "date": "13/06/2025",
  //         "name": "Jupiter Hospital",
  //         "bags": 25,
  //         "waste": 250
  //       },
  //       {
  //         "date": "12/06/2025",
  //         "name": "Deenanath Mangeshkar Hospital",
  //         "bags": 40,
  //         "waste": 320
  //       },
  //       {
  //         "date": "11/06/2025",
  //         "name": "Kokilaben Hospital",
  //         "bags": 80,
  //         "waste": 1200
  //       },
  //     ];
  //
  //     setState(() {
  //       _tableData = responseData;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //       _tableData = [];
  //     });
  //     // Optionally show a snackbar or alert dialog here
  //   }
  // }

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
            onLeadingIconClick: () {Navigator.of(context).popAndPushNamed(AppRoutes.vehicle_nearby_hcf);
              },
    scTitle: 'Assigned HCF',
    centerTile: true,
    showLeading: true,
    ),

    /// Body with tabs
    Positioned.fill(
    top: responsiveHeight(110),
    bottom: responsiveHeight(
    0,
    ), // offset to appear below custom app bar
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10,vertical: 30),
    decoration: BoxDecoration(
    color: kWhiteColor,

    borderRadius: const BorderRadius.only(
    topRight: Radius.circular(40),
    topLeft: Radius.circular(40),
    ),
    ),
    child:SingleChildScrollView(child:
    _isLoading?Center(child:CircularProgressIndicator(color: kPrimaryColor,) ,):
    _tableData.isEmpty||_tableData==null?Datanotfound():Table(
      border: TableBorder.all(color: Colors.grey.shade400, width: 1,
      borderRadius: BorderRadius.all(Radius.circular(10)), ),

      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),

            gradient: LinearGradient(

              colors: [kPrimaryColor, kPrimaryDarkColor],
            ),
          ),
          children: const [
            _TableHeaderCell("Sr.\nNo."),
            _TableHeaderCell("Date"),
            _TableHeaderCell("HCF Name"),
            _TableHeaderCell("Total\nno. of Bags"),
            _TableHeaderCell("Total Waste\nGenerated"),
            _TableHeaderCell("Action"),
          ],
        ),
        ...List.generate(_tableData.length, (index) {
          final row = _tableData[index];
          print(row);
          return TableRow(
            children: [
              _TableCell("${index + 1}"),
              _TableCell(row['date']),
              _TableCell(row['name']),
              _TableCell("${row['bags']}"),
              _TableCell("${row['waste']}", isBold: true),
          GestureDetector(
          onTap: (){
            print(_tableData[index]);
          Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => BioWasteDetailScreen(_tableData[index]),
          ),
          );
          },
          child:Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
          Icons.remove_red_eye,
          color: Colors.lightBlue,
          size: 20,
          ),
          ))
            ],
          );
        }),
      ],
    ),

    )))])), offlineChild: Offline()));
  }
}

/// Table Header Cell Widget
class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

/// Table Data Cell Widget
class _TableCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const _TableCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}







