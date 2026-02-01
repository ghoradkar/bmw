import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/dataNotFound.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Global/AppDrawer.dart';
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
import 'bio_waste_summary.dart';

class BioWasteTableScreen extends StatefulWidget {
  List<Map<String, dynamic>> summarydata;
  BioWasteTableScreen(this.summarydata, {super.key});
  @override
  State<BioWasteTableScreen> createState() => _BioWasteTableScreenState();
}

class _BioWasteTableScreenState extends State<BioWasteTableScreen> {
  List<Map<String, dynamic>> summaryData = [];
  bool isLoading = true;
  bool isEdit = false;
  bool isLoadingColor = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ColorCategory> colorCategories = [];
  ColorCategory? selectedColor;
  Map<int, String> wasteColorLookup = {}; // wastecolourId -> Color Name
  double totalQuantity = 0.0;

  final Map<String, Color> categoryColors = {
    'Yellow': Colors.yellow,
    'Red': Colors.red,
    'Blue': Colors.blue,
    'White': Colors.white,
  };

  @override
  void initState() {
    super.initState();

    widget.summarydata.isEmpty
        ? fetchBioWasteSummary()
        : {
          setState(() {
            summaryData = widget.summarydata;
            // Calculate total quantity
            totalQuantity = summaryData.fold(
              0,
              (sum, item) => sum + (item['quantity'] ?? 0).toDouble(),
            );
            isLoading = false;
          }),
        };
    GetCategoryList();
  }

  Future<void> GetCategoryList() async {
    setState(() {
      isLoadingColor = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('Token');
    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('${baseurl}${CATEGORY_LOOKUP}');

      final response = await http.get(url, headers: headers);

      print(response.body);

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        setState(() {
          wasteColorLookup = {
            for (var item in data) item['lookupDetId']: item['lookupDetDescEn'],
          };
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Authentication Error')));
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
        final Map<String, Map<String, double>> summary = {
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

          final quantity = (item['totalQuantityBagKg'] ?? 0) as double;
          final bags = (item['totalNoOfBags'] ?? 0) as double;

          summary[colorName]!['quantity'] =
              (summary[colorName]!['quantity'] ?? 0) + quantity.toInt();
          summary[colorName]!['bags'] =
              (summary[colorName]!['bags'] ?? 0) + bags.toInt();
        }

        // Convert to list
        summaryData =
            summary.entries.map((entry) {
              return {
                'category': entry.key,
                'quantity': entry.value['quantity'],
                'bags': entry.value['bags'],
              };
            }).toList();
        print('summary');
        print(summaryData);
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
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    return StreamProvider<NetworkStatus>(
      create:
          (context) => NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
          key: _scaffoldKey,
          drawer: AppDrawer(),
          body: Stack(
            children: [
              /// Custom Gradient AppBar
              mAppBar(
                scTitle: t.translate('hcf_data'),
                centerTile: true,
                onLeadingIconClick: () => Navigator.pop(context),
                showLeading: true,
              ),

              /// Body with tabs
              Positioned.fill(
                top: responsiveHeight(110),
                bottom: responsiveHeight(
                  0,
                ), // offset to appear below custom app bar
                child: Container(
                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(40),
                      topLeft: Radius.circular(40),
                    ),
                  ),
                  child:
                      isLoading || isLoadingColor
                          ? const Center(child: CircularProgressIndicator())
                          : summaryData.isEmpty || summaryData == null
                          ? Datanotfound()
                          : SingleChildScrollView(
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
                                    0: FlexColumnWidth(1.2),
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
                                          colors: [
                                            Color(0xFF00B4DB),
                                            Color(0xFF0099CC),
                                          ],
                                        ),
                                      ),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            t.translate('srno'),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            t.translate('category'),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            t.translate('total_weight'),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            t.translate('no_of_bags'),
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
                                                              : Colors
                                                                  .transparent,
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
                                                  summaryData[i]['quantity']
                                                      .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10,
                                                    ),
                                                isDense: true,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Colors.blue,
                                                          ),
                                                    ),
                                                disabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                              ),

                                              onChanged: (val) {
                                                summaryData[i]['quantity'] =
                                                    double.tryParse(val) ?? 0;
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
                                                  summaryData[i]['bags']
                                                      .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10,
                                                    ),
                                                isDense: true,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Colors.blue,
                                                          ),
                                                    ),
                                                disabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                    ),
                                              ),
                                              onChanged: (val) {
                                                summaryData[i]['bags'] =
                                                    double.tryParse(val) ?? 0;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                SizedBox(height: responsiveHeight(50)),

                                // Pie Chart
                               totalQuantity==0?SizedBox(
                                 height: 600,
                                   child:Datanotfound()): Container(
                                  height:
                                      250, // Slightly taller container for better spacing
                                  width: 250, // Make it square for pie chart
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sectionsSpace:
                                              2, // space between slices
                                          centerSpaceRadius:
                                              90, // increase center space
                                          sections: getPieSections(
                                            summaryData,
                                            sectionRadius: 50,
                                          ), // pass radius for slimmer slices
                                          pieTouchData: PieTouchData(
                                            touchCallback: (
                                              FlTouchEvent event,
                                              pieTouchResponse,
                                            ) {
                                              if (!event
                                                      .isInterestedForInteractions ||
                                                  pieTouchResponse == null ||
                                                  pieTouchResponse
                                                          .touchedSection ==
                                                      null)
                                                return;

                                              final index =
                                                  pieTouchResponse
                                                      .touchedSection!
                                                      .touchedSectionIndex;
                                              final category =
                                                  summaryData[index]['category'];
                                              final quantity =
                                                  summaryData[index]['quantity'];
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "$category: $quantity Kg",
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      // Center total
                                      Text(
                                        ' ${t.translate('total')} \n${totalQuantity.toString()} Kg', // now it's an int,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 30),

                                // Legend below Pie Chart
                                totalQuantity==0?SizedBox():Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children:
                                      summaryData.map((item) {
                                        final category = item['category'];
                                        final color =
                                            categoryColors[category] ??
                                            Colors.grey;

                                        // Add border for white slice
                                        final boxDecoration = BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border:
                                              category == 'White'
                                                  ? Border.all(
                                                    color: Colors.grey.shade400,
                                                    width: 1.5,
                                                  )
                                                  : null,
                                        );

                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: boxDecoration,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              category,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
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

  List<PieChartSectionData> getPieSections(
    List<Map<String, dynamic>> data, {
    double sectionRadius = 80,
  }) {
    final colors = {
      'Yellow': Colors.yellow,
      'Red': Colors.red,
      'Blue': Colors.blue,
      'White': Colors.grey[300]!, // light grey for White
    };

    return List.generate(data.length, (i) {
      final item = data[i];
      final category = item['category'];
      final value = (item['quantity'] ?? 0).toDouble();

      // Make text visible for white slice
      final textColor = (category == 'White') ? Colors.black : Colors.white;

      return PieChartSectionData(
        color: colors[category] ?? Colors.grey,
        value: value,
        title: '${value.toInt()} Kg',
        radius: sectionRadius, // use passed radius for slimmer slice
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        borderSide:
            category == 'White'
                ? BorderSide(color: Colors.grey.shade400, width: 1.5)
                : BorderSide.none,
      );
    });
  }
}
