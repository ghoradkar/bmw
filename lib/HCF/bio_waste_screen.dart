import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/AppDrawer.dart';
import 'package:mpcb_bio_waste/Global/app_bar.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:mpcb_bio_waste/network/offline.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../Global/size_config.dart';
import '../Global/url.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import 'add_bio_waste.dart';
import 'barcodeImage.dart';
import 'bio_waste_table.dart';
import 'hcf_model.dart';

class BioWasteDataScreen extends StatefulWidget {
  final int index;
  List<dynamic> summarydata;
  BioWasteDataScreen(this.index,this.summarydata,{super.key});

  @override
  State<BioWasteDataScreen> createState() => _BioWasteDataScreenState();
}

class _BioWasteDataScreenState extends State<BioWasteDataScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading=false;
  List summaryData = [];
  List<HcfWasteModel> wasteData = [];

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
        summaryData = jsonResponse['data'] ?? [];
        print(summaryData.length);
        setState(() {


        wasteData = summaryData.map((item) {
          return HcfWasteModel(
            hcfWasteId: item['hcfWasteId'],
            hcfWasteQntyDetId: item['hcfWasteQntyDetId'],
            hcfWasteQntyId: item['hcfWasteQntyId'],
          );
        }).where((e) =>
        e.hcfWasteQntyDetId != null && e.hcfWasteQntyId != null).toList();
        });
        print(wasteData.length);


      } else {
        summaryData = [];
      }
    } catch (e) {
      print("Error: $e");
      summaryData = [];
    }

    setState(() => isLoading = false);
  }
  Future<void> sendWasteData() async {
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
  void initState() {
    _tabController = TabController(length: 2, vsync: this,initialIndex: widget.index);
    fetchBioWasteSummary();
    _tabController!.addListener(() {
      setState(() {

      }); // Rebuild to update indicator border radius
    });
    super.initState();
  }
  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }
  BorderRadius _getIndicatorBorderRadius() {
    return _tabController!.index == 0
        ? const BorderRadius.only(
      topLeft: Radius.circular(10),
      bottomLeft: Radius.circular(10),
    )
        : const BorderRadius.only(
      topRight: Radius.circular(10),
      bottomRight: Radius.circular(10),
    );
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
            showActions: _tabController!.index==1 && widget.summarydata.isEmpty?true:false,
            actions: [IconButton(onPressed: (){
              sendWasteData();

            }, icon: Icon(Icons.document_scanner_outlined))]
          ),

          /// Body with tabs
          Positioned.fill(
            top: responsiveHeight(110),
            bottom: responsiveHeight(0),// offset to appear below custom app bar
            child: Container(

              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
              ),
              child:  Column(
                children: [
                  SizedBox(height: responsiveHeight(20)),

                  /// TabBar
            Container(
              height: 40,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: _getIndicatorBorderRadius(),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w500,fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400,fontSize: 12),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Add Bio Waste Data'),
                  Tab(text: 'Bio Waste Data Added'),
                ],
              ),
            ),



                  SizedBox(height: 10),

                  /// Tab Views
            Expanded(child:TabBarView(
                      controller: _tabController,
                      children: [
                        AddBioWasteDataTab(

                        ),
                        BioWasteTableScreen([]),
                      ],
                    ),
                  ),
            ],
              ),
            ),
          ),
           ],
      ),
    ), offlineChild: Offline()));
  }
}
