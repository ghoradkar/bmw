import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mpcb_bio_waste/CBWTF/get_bio_waste_data.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/authentication/login_screen.dart';
import 'package:provider/provider.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

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
        isLoading=false;
      });

      fetchNearbyHCFs(); // Call your API or logic
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
    }
  }

  Future<void> fetchNearbyHCFs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await prefs.getString('Token') ?? '';
      var userId = await prefs.getString('UserId');


      final response = await http.post(
        Uri.parse('${baseurl}${CBWTF_MAP}$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
       // body: body,
      );
      print('${baseurl}${CBWTF_MAP}$userId');

      print(response.body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        hcfList = data['data'];
        print(hcfList);
        _generateMarkers();
        print(hcfList.length);
      } else {
        print('API error: ${response.statusCode}');
        if (response.statusCode==401){
          final authService = AuthService();
          authService.logout(context);

        }
      }
    } catch (e) {
      print('Error fetching HCFs: $e');
    }
  }

  Future<void> fetchHCFPolygon(list) async {
    print('list');
    print(list);
    final hcfIds = list
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
       List filteredList = data['data'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GetBioWasteData(filteredList),
          ),
        );
      } else {
        print('API error: ${response.statusCode}');
        if (response.statusCode==401){
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
  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;

    for (int j = 0; j < polygon.length - 1; j++) {
      LatLng a = polygon[j];
      LatLng b = polygon[j + 1];

      if ((a.latitude > point.latitude) != (b.latitude > point.latitude)) {
        double slope = (b.longitude - a.longitude) / (b.latitude - a.latitude);
        double atX = slope * (point.latitude - a.latitude) + a.longitude;

        if (point.longitude < atX) {
          intersectCount++;
        }
      }
    }

    return (intersectCount % 2) == 1;
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
  // Tap handler to add polygon points
  void _onMapTap(LatLng position) {
    setState(() {
      final markerId = MarkerId('polygon_${_polygonPoints.length}');
      _polygonPoints.add(position);
      _polygonMarkers.add(
        Marker(
          markerId: markerId,
          position: position,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onDragEnd: (newPosition) {
            final index = _polygonPoints.indexWhere((p) => p == position);
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

  // void _filterMarkersWithinPolygon() {
  //   Set<Marker> insidePolygon = {};
  //   for (var marker in _markers) {
  //     if (_isPointInsidePolygon(marker.position, _polygonPoints)) {
  //       insidePolygon.add(marker);
  //     }
  //   }
  //
  //   setState(() {
  //     _markers = insidePolygon;
  //   });
  // }


  void _filterMarkersWithinPolygon() {
    Set<Marker> insidePolygon = {};
    List<dynamic> filteredList = [];

    for (var marker in _markers) {
      if (_isPointInsidePolygon(marker.position, _polygonPoints)) {
        insidePolygon.add(marker);

        // Match marker with HCF from allHCFList
        final hcf = hcfList.firstWhere(
              (h) => h['geoTagLatitude'] == marker.position.latitude && h['geoTagLongitude'] == marker.position.longitude,

        );
        filteredList.add(hcf);
      }
    }

    setState(() {
      _markers = insidePolygon;
     filteredList;
     print(filteredList);
    });
    //fetchHCFPolygon(filteredList);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GetBioWasteData(filteredList),
      ),
    );

    // Navigate to next page with data

  }




  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
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
            scTitle: 'CBWTF Bio Waste Data',
            centerTile: true,

            //onLeadingIconClick: () => Navigator.pop(context),
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
              child:  isLoading?Center(child: CircularProgressIndicator(color: kPrimaryColor,),):
              Column(
                children: [
                  SizedBox(height: responsiveHeight(10)),
                  // Padding(
                  //   padding: EdgeInsets.all(10),
                  //   child: Column(
                  //     children: [
                  //       Row(
                  //         children: [
                  //           _buildLocationBox(
                  //             Icons.location_on,
                  //             'Latitude',
                  //             '${_center!.latitude.toStringAsFixed(6)} N',
                  //           ),
                  //           const SizedBox(width: 12),
                  //           _buildLocationBox(
                  //             Icons.location_on,
                  //             'Longitude',
                  //             '${_center!.longitude.toStringAsFixed(6)} E',
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 12),
                  //       Row(
                  //         children: [
                  //           _buildLocationBox(
                  //             Icons.map,
                  //             'Range in km.',
                  //             '$_radiusInKm km',
                  //             trailing: DropdownButton<double>(
                  //               value: _radiusInKm,
                  //               items:
                  //                   [2, 4, 6, 8, 10].map((e) {
                  //                     return DropdownMenuItem(
                  //                       value: e.toDouble(),
                  //                       child: Text("$e km"),
                  //                     );
                  //                   }).toList(),
                  //               onChanged: (value) {
                  //                 if (value != null) {
                  //                   setState(() {
                  //                     _radiusInKm = value;
                  //                     fetchNearbyHCFs();
                  //
                  //                   });
                  //                 }
                  //               },
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  SizedBox(
                    height: responsiveHeight(700),
                    child:
                    Padding(
                      padding: EdgeInsets.only(top: 10,left: 10,right: 10,bottom: 10),
                      child: GoogleMap(

                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: _center!,
                        zoom: 13,
                      ),

                      markers: _markers.union(_polygonMarkers),
                      polygons: _polygons,
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
                    )),
                  ),
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
                        _polygonPoints.clear();
                        _polygons.clear();
                        _markers = _allMarkers;
                        _clearPolygon();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset"),
                  ),
                   TextButton.icon(
                     onPressed: () {
                       setState(() {
                         // _isDrawing = !_isDrawing;
                         // if (!_isDrawing) {
                         _polygonPoints.isNotEmpty?

                           _filterMarkersWithinPolygon():
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Please Select Hospitals'),

                           ),
                         );;
                         // } else {
                         //   _polygonPoints.clear();
                         //   _polygons.clear();
                         //   _clearPolygon();
                         // }
                       });
                     },
                     icon: const Icon(Icons.done),
                     label: const Text("Ok"),
                   )



              ]),
           ])),
          ),
        ],
      ),
      )), offlineChild: Offline()));
  }


}
