import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../Localization/app_localization.dart';
import '../authentication/logout.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class DiscoverNearbyHCFScreen extends StatefulWidget {
  @override
  _DiscoverNearbyHCFScreenState createState() => _DiscoverNearbyHCFScreenState();
}

class _DiscoverNearbyHCFScreenState extends State<DiscoverNearbyHCFScreen> {

  LatLng? _center; // Sample coordinates
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double _radiusInKm = 4;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  late GoogleMapController _mapController;
  bool isLoading = true;
  List hcfList = [];
  bool _isLoading=false;
  Set<Marker> _allMarkers = {};
  DateTime? rangeStartDate;
  DateTime? rangeEndDate;
  bool showCalendar = false;
  String? totalhcf='0.0';
   String? totalweight='0.0';
  String? totalBags='0.0';
  bool _isSatellite = false;

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    // Check service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    // Handle permanent denial
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission permanently denied.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings(); // Opens system app settings
            },
          ),
        ),
      );
      return;
    }

    // Fetch location
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
      // Call your API or logic
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
    }
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
        Uri.parse('${baseurl}${VEHICLE_DASHBOARD_COUNT}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      print(body);
      print('${baseurl}${VEHICLE_DASHBOARD_COUNT}');
      print(response.body);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        totalweight=res['data']['totalWaste'].toString();
        totalhcf=res['data']['totalHcf'].toString();
        setState(() {

        });
        // Process dashboard count data if needed
      }
    } catch (_) {
      _showError("Failed to fetch dashboard count");
    }

    setState(() => _isLoading = false);
  }
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }


  Future<void> fetchNearbyHCFs(from,to) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      var userId = await prefs.getString('UserId') ?? "";
      final today = DateTime.now().toString().substring(0, 10);
      final body = {
        "scheduleFromDate": from,
        "scheduleToDate":to,
        "userId": userId
      };



      final response = await http.post(
        Uri.parse('${baseurl}${CBWTF_MAP}$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        //body: jsonEncode(body)

      );
      print('${baseurl}${CBWTF_MAP}');
     // print(body);

      print(response.body);


      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        hcfList = data['data'];
        print(hcfList);
        _generateMarkers();
        print(hcfList.length);
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

  void _generateMarkers() {
    Set<Marker> tempMarkers = {};
    List<LatLng> latLngs = [];


    for (var hcf in hcfList) {
      final lat = double.tryParse(hcf['geoTagLatitude'].toString());
      final lng = double.tryParse(hcf['geoTagLongitude'].toString());
      final name = hcf['nameOfHcf'];
      final hcfCode = hcf['hcfCode'];

      if (lat != null && lng != null) {
        final position = LatLng(lat, lng);
        latLngs.add(position);

        tempMarkers.add(
          Marker(
            markerId: MarkerId(hcfCode),
            position: position,
            infoWindow: InfoWindow(title: name),
            // onTap: () {
            //   Navigator.of(context).pushNamed(AppRoutes.get_bio_waste );
            // },
          ),
        );
        _allMarkers = tempMarkers; // Store original
        _markers = tempMarkers;
      }
    }

    setState(() {
      _markers = tempMarkers;
      _circles = {
        Circle(
          circleId: CircleId('range'),
          center: _center!,
          radius: _radiusInKm * 1000,
          fillColor: Colors.purple.withOpacity(0.2),
          strokeColor: Colors.purple,
          strokeWidth: 2,
        ),
      };
    });

    if (latLngs.isNotEmpty) {
      final bounds = _createBounds(latLngs);
      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    double x0 = positions.first.latitude;
    double x1 = positions.first.latitude;
    double y0 = positions.first.longitude;
    double y1 = positions.first.longitude;

    for (var latLng in positions) {
      x0 = x0 < latLng.latitude ? x0 : latLng.latitude;
      x1 = x1 > latLng.latitude ? x1 : latLng.latitude;
      y0 = y0 < latLng.longitude ? y0 : latLng.longitude;
      y1 = y1 > latLng.longitude ? y1 : latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    final today = DateTime.now().toString().substring(0, 10);
    fetchDashboardCount(today, today);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();
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
                          scTitle:  t.translate('assigned_hcf'),
                          centerTile: true,
                          leadingWidget: Builder(
                            builder: (context) =>
                                IconButton(
                                  icon: const Icon(
                                      Icons.menu, color: Colors.white),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                          ),
                          showLeading: true,
                          showActions: true,
                          actions: [IconButton(onPressed: () {
                            _openFilterBottomSheet(context,t);
                          },
                              icon: Icon(
                                Icons.filter_alt_outlined, color: kWhiteColor,))
                          ]

                      ),

                      /// Body with tabs
                      Positioned.fill(
                          top: responsiveHeight(110),
                          bottom: responsiveHeight(0),
                          // offset to appear below custom app bar
                          child:Container(
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


                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, ),
                            child:Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Container(
                                    margin:EdgeInsets.all(5),
                                    padding: EdgeInsets.all(5),
                                    height: 50,
                                    width:140,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade500),
                                        borderRadius: BorderRadius.all(Radius.circular(10))),
                                    child:Row(children: [
                                      Icon(Icons.local_hospital_outlined,color: kPrimaryColor,),
                                      SizedBox(width: 10,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [Text( t.translate('total_hcf'),style: TextStyle(fontSize: 10),),
                                        Text('${totalhcf!}',style: TextStyle(fontWeight: FontWeight.bold)),


                                      ],),])),

                                Container(
                                  margin:EdgeInsets.all(5),
                                  padding: EdgeInsets.all(5),
                                  height: 50,
                                   width:140,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade500),
                                      borderRadius: BorderRadius.all(Radius.circular(10))),
                                  child:Row(children: [
                                    Icon(Icons.transfer_within_a_station,color: kPrimaryColor,), SizedBox(width: 10,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [Text( t.translate('total_waste'),style: TextStyle(fontSize: 10),),
                                    Text('${totalweight!} Kg',style: TextStyle(fontWeight: FontWeight.bold),),


                                  ],),])),




                              ],),),
                          SizedBox(height: 10,),





                          /// Google Map
                          Container(
                            height: 565,


                            decoration: BoxDecoration(
                              color: kWhiteColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(40),
                                topLeft: Radius.circular(40),
                              ),
                            ),
                            child: isLoading ? Center(
                              child: CircularProgressIndicator(
                                color: kPrimaryColor,),) : Stack(
                              children: [


                                /// Wrap GoogleMap in ClipRRect for rounded corners
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(40),
                                    topRight: Radius.circular(40),
                                  ),
                                  child:Stack(
                                      children: [ GoogleMap(
                                    onMapCreated: (controller) =>
                                    _mapController = controller,
                                    initialCameraPosition: CameraPosition(
                                      target: _center!,
                                      zoom: 15.0,
                                    ),
                                    markers: _markers,
                                    mapType: _isSatellite ? MapType.satellite : MapType.normal,
                                    circles: _circles,

                                    myLocationEnabled: true,
                                    zoomControlsEnabled: false,
                                  )
                        , Positioned(
                                          bottom: 120,
                                          right: 10,
                                          child: Container(
                                              height: 35,
                                              width: 35,
                                              decoration: BoxDecoration(
                                                color: kWhiteColor.withOpacity(0.7),

                                              ),
                                              child:
                                              IconButton(onPressed: (){
                                                setState(() {
                                                  _isSatellite = !_isSatellite; // Switch map type
                                                });
                                              }, icon: Icon(Icons.layers,size: 20,color: Colors.black54,))),

                                        ),])
                                ),


                                Positioned(
                                  top: 60,
                                  left: 24,
                                  right: 24,
                                  child: _buildLocationBox(
                                    Icons.map,
                                      t.translate('range_km'),
                                    '$_radiusInKm km',
                                    trailing: DropdownButton<double>(
                                      value: _radiusInKm,
                                      items:
                                      [2, 4, 6, 8, 10].map((e) {
                                        return DropdownMenuItem(
                                          value: e.toDouble(),
                                          child: Text("$e km"),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _radiusInKm = value;
                                            //fetchNearbyHCFs();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                /// Bottom Button
                                Positioned(
                                  bottom: 60,
                                  left: 24,
                                  right: 24,
                                  child: SizedBox(
                                    width: responsiveWidth(280),
                                    child: AppButton(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 15,
                                      ),
                                      text:  t.translate('next'),
                                      onPressed: () {
                                        Navigator.of(context).popAndPushNamed(
                                            AppRoutes.assigned_hcf);
                                        setState(() {});
                                      },
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          ])))
                    ])), offlineChild: Offline()));
  }

  Widget _buildLocationBox(IconData icon,
      String label,
      String value, {
        Widget? trailing,
      }) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _openFilterBottomSheet(BuildContext context,t) {
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
                    height: showCalendar ? 600 : 300,
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
                                    showCalendar = false;
                                  });
                                  fetchNearbyHCFs(rangeStartDate.toString().substring(0,10),rangeEndDate.toString().substring(0,10));
                                  fetchDashboardCount(rangeStartDate.toString().substring(0,10),rangeEndDate.toString().substring(0,10));
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
                  ? t.translate('custom_date')                  : rangeEndDate == null
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

}