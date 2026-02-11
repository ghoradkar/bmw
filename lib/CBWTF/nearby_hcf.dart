import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/CBWTF/apiservice.dart';
import 'package:mpcb_bio_waste/CBWTF/get_bio_waste_data.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/Localization/app_localization.dart';
import 'package:mpcb_bio_waste/authentication/login_screen.dart';
import 'package:provider/provider.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
 import '../Global/app_dialog.dart';
import '../Global/app_dropdown.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../authentication/logout.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class NearbyHCFScreen extends StatefulWidget {
  @override
  _NearbyHCFScreenState createState() => _NearbyHCFScreenState();
}

class _NearbyHCFScreenState extends State<NearbyHCFScreen> {
  late GoogleMapController _mapController;
  LatLng? _center;
  double _radiusInKm = 10;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  List<dynamic> hcfList = [];
  bool isLoading=true;
  List<LatLng> _polygonPoints = [];
  Set<Polygon> _polygons = {};
  Set<Marker> _polygonMarkers = {};
  Set<Marker> _allMarkers = {}; // Keep all fetched marker
  bool _isDrawing = false;// for draggable polygon markers
  String? osVersion;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? rangeStartDate;
  DateTime? rangeEndDate;
  bool showCalendar = false;
  MapType _currentMapType = MapType.normal;
  bool _isSatellite = false; // Track current map type
  List <Map<String,dynamic>>vehicleList=[];
  Map<String,dynamic>? selectedVehicle;
  bool _isLoading=false;
  String? totalhcf='0.0';
  // String? totalweight='0.0';
   String? totalBags='0.0';
  Set<int> _selectedHcfIds = {}; // selected HCFs
  List<Map<String, dynamic>> _selectedHcfs = [];
  Map<int, Map<String, dynamic>> _groupedHcfMap = {};


  double totalWeight = 0;
  double totalBagsCount = 0;



  Future<DateTime?> _pickDate(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
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
  }

  Future<void> fetchDashboardCount(String startDate, String endDate) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final userId = prefs.getString('UserId');

      final body = {
        "scheduleFromDate": startDate,
        "scheduleToDate": endDate,
        "userId": userId
      };

      final response = await http.post(
        Uri.parse('${baseurl}${CBWTF_DASHBOARD_COUNT}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        // Process dashboard count data if needed
      }
    } catch (_) {
      _showError("Failed to fetch dashboard count");
    }

    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchVehicle();
    final today = DateTime.now().toString().substring(0, 10);
    fetchDashboardCount(today, today);
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    if (!await Geolocator.isLocationServiceEnabled()) {
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission permanently denied.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: Geolocator.openAppSettings,
          ),
        ),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });

      DateTime now = DateTime.now();
      DateTime fromDate = DateTime(now.year, now.month - 1, now.day);

      fetchNearbyHCFs(fromDate.toString().substring(0, 10),
          now.toString().substring(0, 10));
    } catch (e) {
      _showError('Failed to get location');
    }
  }

  Future<void> fetchNearbyHCFs(String startDate, String endDate) async {
    try {
      setState(() {
        isLoading=true;
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final userId = prefs.getString('UserId');

      // final body = {
      //   "scheduleFromDate": startDate,
      //   "scheduleToDate": endDate,
      //   "userId": userId
      // };

      final response = await http.post(
        Uri.parse('${baseurl}${CBWTF_MAP}$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        //body: jsonEncode(body),
      );
      print('${baseurl}${CBWTF_MAP}$userId');
     // print(body);
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print(data);
        hcfList = data['data'];
        _generateMarkers();
        _prepareGroupedHcfData();
        setState(() {
          isLoading=false;
        });
      } else if (response.statusCode == 401) {
        AuthService().logout(context);
        setState(() {
          isLoading=false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading=false;
      });
      print('Error fetching HCFs: $e');
    }
  }

  void _generateMarkers() {
    Set<Marker> tempMarkers = {};

    for (var hcf in hcfList) {
      final lat = double.tryParse(hcf['geoTagLatitude'].toString());
      final lng = double.tryParse(hcf['geoTagLongitude'].toString());
      final hcfId = hcf['hcfId'];

      if (lat != null && lng != null) {
        final isSelected = _selectedHcfIds.contains(hcfId);

        tempMarkers.add(
          Marker(
            markerId: MarkerId(hcfId.toString()),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
            onTap: () => _onMarkerTap(hcf),
            infoWindow: InfoWindow(title: hcf['nameOfHcf']),
          ),
        );
      }
    }

    setState(() {
      _markers = tempMarkers;
      _allMarkers = tempMarkers;
    });
  }

  // void _prepareGroupedHcfData() {
  //   _groupedHcfMap.clear();
  //
  //   for (var hcf in hcfList) {
  //     final int hcfId = hcf['hcfId'];
  //     if (_groupedHcfMap.containsKey(hcfId)) {
  //       _groupedHcfMap[hcfId]!['totalQtyinBag'] += (hcf['totalWaste'] ?? 0).toDouble();
  //       _groupedHcfMap[hcfId]!['totalNoBag'] += (hcf['totalBag'] ?? 0).toInt();
  //     } else {
  //       _groupedHcfMap[hcfId] = {
  //         ...hcf,
  //         'totalWaste': (hcf['totalWaste'] ?? 0).toDouble(),
  //         'totalBag': (hcf['totalBag'] ?? 0).toInt(),
  //       };
  //     }
  //   }
  // }
  void _prepareGroupedHcfData() {
    _groupedHcfMap.clear();

    for (var hcf in hcfList) {
      final int hcfId = hcf['hcfId'];

      final double qty =
      (hcf['totalQtyinBag'] ?? 0).toDouble();
      final int bags =
      (hcf['totalNoBag'] ?? 0).toInt();

      if (_groupedHcfMap.containsKey(hcfId)) {
        _groupedHcfMap[hcfId]!['totalQtyinBag'] += qty;
        _groupedHcfMap[hcfId]!['totalNoBag'] += bags;
      } else {
        _groupedHcfMap[hcfId] = {
          ...hcf,
          'totalQtyinBag': qty,
          'totalNoBag': bags,
        };
      }
    }
  }


  void _onMarkerTap(Map<String, dynamic> hcf) {
    final hcfId = hcf['hcfId'];
    print(hcf);
    setState(() {
      if (_selectedHcfIds.contains(hcfId)) {
        _selectedHcfIds.remove(hcfId);
        _selectedHcfs.removeWhere((e) => e['hcfId'] == hcfId);
      } else {
        _selectedHcfIds.add(hcfId);
        _selectedHcfs.add(hcf);
      }
      _calculateTotals();
      _generateMarkers();
    });
  }
  void _calculateTotals() {
    double weightSum = 0;
    double bagSum = 0;

    for (var hcfId in _selectedHcfIds) {
      final hcf = _groupedHcfMap[hcfId];
      if (hcf != null) {
        weightSum += (hcf['totalQtyinBag'] ?? 0).toDouble();
        bagSum += (hcf['totalNoBag'] ?? 0).toInt();
      }
    }

    setState(() {
      totalWeight = weightSum;
      totalBagsCount = bagSum.toDouble();
      totalhcf = _selectedHcfIds.length.toString();
      totalBags = bagSum.toString();
    });
  }


  // void _calculateTotals() {
  //   double weightSum = 0;
  //   double bagSum = 0;
  //
  //   for (var hcfId in _selectedHcfIds) {
  //     final hcf = _groupedHcfMap[hcfId];
  //     if (hcf != null) {
  //       weightSum += hcf['totalWaste'];
  //       bagSum += hcf['totalBag'];
  //     }
  //   }
  //
  //   setState(() {
  //     totalWeight = weightSum;
  //     totalBagsCount = bagSum;
  //     totalhcf = _selectedHcfIds.length.toString();
  //     totalBags = totalBagsCount.toString();
  //   });
  // }

  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length - 1; i++) {
      final LatLng a = polygon[i];
      final LatLng b = polygon[i + 1];

      if (((a.latitude > point.latitude) != (b.latitude > point.latitude)) &&
          (point.longitude < (b.longitude - a.longitude) *
              (point.latitude - a.latitude) /
              (b.latitude - a.latitude) +
              a.longitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  // void _selectHcfsInsidePolygon(List<LatLng> polygonPoints) {
  //   _selectedHcfIds.clear();
  //   _selectedHcfs.clear();
  //
  //   for (var hcf in _groupedHcfMap.values) {
  //     final lat = double.tryParse(hcf['latitude'].toString());
  //     final lng = double.tryParse(hcf['logitude'].toString());
  //     if (lat == null || lng == null) continue;
  //
  //     final point = LatLng(lat, lng);
  //     if (_isPointInsidePolygon(point, polygonPoints)) {
  //       _selectedHcfIds.add(hcf['hcfId']);
  //       _selectedHcfs.add(hcf);
  //     }
  //   }
  //
  //   _calculateTotals();
  //   _generateMarkers();
  //
  // }
  void _selectHcfsInsidePolygon(List<LatLng> polygonPoints) {
    _selectedHcfIds.clear();
    _selectedHcfs.clear();

    for (var hcf in _groupedHcfMap.values) {
      final lat = double.tryParse(hcf['geoTagLatitude'].toString());
      final lng = double.tryParse(hcf['geoTagLongitude'].toString());

      if (lat == null || lng == null) continue;

      final point = LatLng(lat, lng);

      if (_isPointInsidePolygon(point, polygonPoints)) {
        _selectedHcfIds.add(hcf['hcfId']);
        _selectedHcfs.add(hcf);
      }
    }

    _calculateTotals();
    _generateMarkers();
  }


  void _onMapTap(LatLng position) {
    setState(() {
      _polygonPoints.add(position);
      _polygonMarkers.add(
        Marker(
          markerId: MarkerId('polygon_${_polygonPoints.length}'),
          position: position,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onDragEnd: (newPosition) {
            final index = _polygonPoints.indexOf(position);
            if (index != -1) {
              _polygonPoints[index] = newPosition;
              _updatePolygon();
            }
          },
        ),
      );
      _updatePolygon();
    });
  }

  void _updatePolygon() {
    setState(() {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('user_polygon'),
          points: _polygonPoints,
          fillColor: Colors.green.withOpacity(0.3),
          strokeColor: Colors.green,
          strokeWidth: 2,
        ),
      };
    });
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
      _polygonMarkers.clear();
      _polygons.clear();
    });
  }

  void _filterMarkersWithinPolygon() {
    _selectHcfsInsidePolygon(_polygonPoints);

  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }




  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();
    return StreamProvider<NetworkStatus>(
        create: (context) =>
        NetworkStatusService().networkStatusController.stream,
        initialData: NetworkStatus.Online,
        child: NetworkAwareWidget(
        onlineChild:Scaffold(
        key: _scaffoldKey,

      drawer: AppDrawer(),
      body: SingleChildScrollView(child:Stack(
        children: [
          /// Custom Gradient AppBar
          mAppBar(
            scTitle:  t.translate('cbwtf_vehicle_assigning'),
            centerTile: true,

            //onLeadingIconClick: () => Navigator.pop(context),
            leadingWidget: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            showLeading: true,
            showActions: true,
            actions: [IconButton(onPressed: (){
              _openFilterBottomSheet(context,t);
            }, icon: Icon(Icons.filter_alt_outlined,color: kWhiteColor,))]
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
              child:  isLoading||_isLoading?Center(child: CircularProgressIndicator(color: kPrimaryColor,),):
              Column(
                children: [
                  SizedBox(height: responsiveHeight(10)),
                  // Padding(padding:EdgeInsets.only(left: 20,right: 20,top: 10,bottom: 10), child:validatedApiDropdown(
                  //   hint: "Assign Vehicle",
                  //   value: selectedVehicle,
                  //   items:vehicleList,
                  //   displayKey: "vehicleNo",
                  //   icon: Icons.fire_truck_outlined,
                  //   errorText: "Please select HCF type",
                  //   onChanged: (v) => setState(() => selectedVehicle = v),
                  // ))
                  // ,
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                    child: InkWell(
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
                          hint:  t.translate('assign_vehicle'),
                          value: selectedVehicle,
                          items: vehicleList,
                          displayKey: "vehicleNo",
                          icon: Icons.fire_truck_outlined,
                          errorText: "Please select HCF type",
                          onChanged: (v) {}, // handled via bottom sheet
                        ),
                      )),
                    ),
                  ),
              Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, ),
                  child:Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Container(
                      margin:EdgeInsets.all(5),
                      padding: EdgeInsets.all(5),
                      height: 90,
                      width:90,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade500),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(children: [
                      Icon(Icons.local_hospital_outlined,color: kPrimaryColor,),
                      Text( t.translate('total_hcf'),style: TextStyle(fontSize: 10),),
                      Text(totalhcf!),
                      

                    ],),),
                    Container(
                      margin:EdgeInsets.all(5),
                      padding: EdgeInsets.all(5),
                      height: 90,
                     // width:100,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade500),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(children: [
                        Icon(Icons.transfer_within_a_station,color: kPrimaryColor,),
                        Text( t.translate('total_weight'),style: TextStyle(fontSize: 10),),
                        Text('${totalWeight!} Kg'),


                      ],),),
                    Container(
                      margin:EdgeInsets.all(5),
                      padding: EdgeInsets.all(5),
                      height: 90,
                    //  width:100,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade500),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        Icon(Icons.shopping_bag_outlined,color: kPrimaryColor,),
                        Text( t.translate('total_bags'),style: TextStyle(fontSize: 10),),
                        Text(totalBags!),


                      ],),)



                  ],),),





                  SizedBox(
                    height: responsiveHeight(520),
                    child:

                          SizedBox(
                            height: MediaQuery.of(context).size.height,
                            child: Padding(
                      padding: EdgeInsets.only(top: 10,left: 10,right: 10,bottom: 10),
                      child: Stack(
                          children: [GoogleMap(

                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: _center!,
                        zoom: 13,
                      ),

                      markers: _markers.union(_polygonMarkers),
                      polygons: _polygons,
                        mapType: _isSatellite ? MapType.satellite : MapType.normal,
                     // circles: _circles,
                      onTap: _onMapTap,
                      // onLongPress: (LatLng latLng) {
                      //   if (_isDrawing) {
                      //     setState(() {
                      //       _polygonPoints.add(latLng);
                      //       _polygons = {
                      //         Polygon(
                      //           polygonId: PolygonId('drawn_area'),
                      //           points: _polygonPoints,
                      //           strokeColor: Colors.blue,
                      //           fillColor: Colors.blue.withOpacity(0.2),
                      //           strokeWidth: 2,
                      //         ),
                      //       };
                      //     });
                      //   }
                      // },


                      myLocationEnabled: true,
                    ),
                    Positioned(
                      top: 60,
                      right: 10,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: kWhiteColor.withOpacity(0.7),

                        ),
                          child:
                      IconButton(onPressed: (){
                        setState(() {
                          _isSatellite = !_isSatellite; // Switch map type
                        });
                      }, icon: Icon(Icons.layers,size: 25,color: Colors.black54,))),

                    ),])),),),

                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                  //  ElevatedButton(
                  //   onPressed: _clearPolygon,
                  //   child: const Text("Clear"),
                  // ),
                  //  TextButton.icon(
                  //   onPressed: () {
                  //     setState(() {
                  //       _isDrawing = !_isDrawing;
                  //       if (!_isDrawing) {
                  //         _filterMarkersWithinPolygon();
                  //       } else {
                  //         _polygonPoints.clear();
                  //         _polygons.clear();
                  //         _clearPolygon();
                  //       }
                  //     });
                  //   },
                  //   icon: Icon(_isDrawing ? Icons.check : Icons.edit),
                  //   label: Text(_isDrawing ? "Done" : "Draw"),
                  // ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {

                        _clearPolygon();
                        _polygonPoints.clear();
                        _polygons.clear();
                        _polygonMarkers.clear();

                        _selectedHcfIds.clear();
                        _selectedHcfs.clear();

                        totalhcf = '0';
                        totalWeight = 0;
                        totalBags = '0';

                        _markers = _allMarkers;
                        _generateMarkers();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label:  Text( t.translate('reset')),
                  ),
                   TextButton.icon(
                     onPressed: () {
                       _assignVehicleToSelectedHcfs(t);
                       // setState(() {
                       //   // _isDrawing = !_isDrawing;
                       //   // if (!_isDrawing) {
                       //   _polygonPoints.isNotEmpty?
                       //
                       //     _filterMarkersWithinPolygon():
                       //   ScaffoldMessenger.of(context).showSnackBar(
                       //     SnackBar(
                       //       content: Text('Please Select Hospitals'),
                       //
                       //     ),
                       //   );

                      // });
                     },
                     icon: const Icon(Icons.done),
                     label:  Text( t.translate('ok'),),
                   )



              ]),
           ])),
          ),
        ],
      ),
      )), offlineChild: Offline()));
  }
  void _openFilterBottomSheet(BuildContext contex,t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// 🔹 TRANSPARENT CLOSE ICON (ABOVE SHEET)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: kWhiteColor),
                        color: Colors.transparent,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        shape: BoxShape.rectangle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: kWhiteColor,
                      ),
                    ),
                  ),

                  /// 🔹 ACTUAL BOTTOM SHEET
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: showCalendar?600:300,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Text(
                    t.translate('filters'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// Date range box
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              showCalendar = !showCalendar;
                            });
                          },
                          child: _dateRangeBox(t),
                        ),

                        /// Inline calendar
                        if (showCalendar) ...[
                          const SizedBox(height: 12),
                          CalendarDatePicker(
                            initialDate:
                            rangeStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            onDateChanged: (date) {
                              setModalState(() {
                                if (rangeStartDate == null ||
                                    rangeEndDate != null) {
                                  rangeStartDate = date;
                                  rangeEndDate = null;
                                } else if (date.isAfter(rangeStartDate!)) {
                                  rangeEndDate = date;
                                  showCalendar = false;
                                }
                              });
                            },
                          ),
                        ],

                        const Spacer(),

                        /// Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setModalState(() {
                                    rangeStartDate = null;
                                    rangeEndDate = null;
                                    showCalendar = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                ),
                                child:  Text(
            t.translate('cancel'),
                                  style: TextStyle(color: kBlackColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: rangeStartDate != null &&
                                    rangeEndDate != null
                                    ? () {
                                  Navigator.pop(context);
                                  debugPrint(
                                      "Range: $rangeStartDate → $rangeEndDate");
                                  setState(() {
                                    showCalendar=false;

                                  });

                                  fetchNearbyHCFs(rangeStartDate.toString().substring(0,10),rangeEndDate.toString().substring(0,10));
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                ),
                                child:  Text(
            t.translate('search'),
                                  style: TextStyle(color: kWhiteColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dateRangeBox(t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          //const Icon(Icons.date_range, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rangeStartDate == null
                  ?  t.translate('custom_date')
                  : rangeEndDate == null
                  ? "From ${DateFormat('dd-MM-yyyy').format(rangeStartDate!)}"
                  : "${DateFormat('dd-MM-yyyy').format(rangeStartDate!)} - "
                  "${DateFormat('dd-MM-yyyy').format(rangeEndDate!)}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(
            showCalendar
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
          ),
        ],
      ),
    );
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
                  t.translate('select_vehicle'),
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
  void _assignVehicleToSelectedHcfs(t) async{
    if (_polygonPoints.isNotEmpty) {
      _selectHcfsInsidePolygon(_polygonPoints);
    }
    if (_selectedHcfIds.isEmpty) {
      // No HCF selected
      _showError("Please select at least one HCF or draw a polygon");
      return;
    }

    if (selectedVehicle == null || selectedVehicle!.isEmpty) {
      // Vehicle not selected
      _showError("Please select a vehicle");
      return;
    }
    print('done');
    print(_selectedHcfs);
    // var body = await ApiService.buildWastePayloadList(
    //   inputList: _selectedHcfs,
    //   vehicle: selectedVehicle!,
    // );
    // print(body)
    // ;
    var bodyList = await ApiService.buildWastePayloadList(
      inputList: _selectedHcfs,
      vehicle: selectedVehicle!,
    );

    // for (var item in bodyList) {
    //   await ApiService.AssignVehicle(context, item);
    // }

    if (bodyList.isNotEmpty) {
      for (var item in bodyList) {
        final value =await ApiService.AssignVehicle(context, item);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${value['message']}')),
      );
      if (value['status'] == 'Succes') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialog(
            buttonText: t.translate('save'),

            message:t.translate('vehicle_assigned'),

            onOk: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) =>NearbyHCFScreen()),
              );
           //  Navigator.pop(context);



              //launchUrl(Uri.parse('https://www.ecmpcb.in/registration'));
            },
          ),
        );


      }}}

    // Both HCFs/polygon and vehicle selected → call API
   // _hitAssignVehicleApi();

  }









}
