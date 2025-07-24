import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/AppDrawer.dart';
import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_routes.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../authentication/logout.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';

class DiscoverNearbyHCFScreen extends StatefulWidget {
  @override
  _DiscoverNearbyHCFScreenState createState() => _DiscoverNearbyHCFScreenState();
}

class _DiscoverNearbyHCFScreenState extends State<DiscoverNearbyHCFScreen> {

   LatLng? _center;// Sample coordinates
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double _radiusInKm = 10;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  late GoogleMapController _mapController;
  bool isLoading=true;
  List hcfList=[];
  Set<Marker> _allMarkers = {};

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
      final token = prefs.getString('Token') ?? '';

      final body = jsonEncode({

        "geoTagLatitude": null,
        "geoTagLongitude": null,
        "distanceCbwtfHcf":_radiusInKm


      });

      final response = await http.post(
        Uri.parse('${baseurl}${CBWTF_MAP}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      print('${baseurl}${CBWTF_MAP}');
      print(body);
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

      body:Stack(
        children: [
        /// Custom Gradient AppBar
        mAppBar(
        scTitle: 'Discover Nearby HCF',
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
    child:
    /// Google Map
    Container(


      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(40),
          topLeft: Radius.circular(40),
        ),
      ),
      child:isLoading?Center(child: CircularProgressIndicator(color: kPrimaryColor,),):Stack(
          children: [
            /// Wrap GoogleMap in ClipRRect for rounded corners
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
              child: GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _center!,
                  zoom: 15.0,
                ),
                   markers: _markers,
                circles: _circles,

                myLocationEnabled: true,
                zoomControlsEnabled: false,
              ),
            ),


            Positioned(
                top: 60,
                left: 24,
                right: 24,
                child: _buildLocationBox(
                  Icons.map,
                  'Range in km.',
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
                          fetchNearbyHCFs();

                        });
                      }
                    },
                  ),
                ),
              ) ,

            /// Bottom Button
            Positioned(
              bottom: 10,
              left: 24,
              right: 24,
              child: SizedBox(
                width: responsiveWidth(280),
                child: AppButton(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 15,
                  ),
                  text: 'Next',
                  onPressed: () {
                    Navigator.of(context).popAndPushNamed(AppRoutes.assigned_hcf);
                    setState(() {});
                  },
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ],
        ),
      )
    )])), offlineChild: Offline()));
  }
}
Widget _buildLocationBox(
    IconData icon,
    String label,
    String value, {
      Widget? trailing,
    }) {
  return  Container(
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

