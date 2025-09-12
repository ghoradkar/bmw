import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/app_button.dart';
import 'package:mpcb_bio_waste/Global/app_textfield.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'dart:convert';

import 'package:mpcb_bio_waste/Global/images.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/homeScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../CBWTF_Disposal/disposal_overall_colection.dart';
import '../CBWTF_Reception/overall_Data_collection.dart';
import '../Global/app_routes.dart';
import 'forget_password.dart';

class LoginScreen extends StatefulWidget {
  final String reset;
  const LoginScreen(this.reset, {super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool keepMeSignedIn = true;
  bool isLoading = false;
  String? userRole;
  bool isobscured=false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tableData = [];
  List <Map<String, dynamic>> formattedList=[];

  String? osVersion;
  final secureStorage = FlutterSecureStorage();
  Map<String,dynamic> device_info={};
  Future<void> saveCredentials(String username, String password) async {
    await secureStorage.write(key: 'username', value: username);
    await secureStorage.write(key: 'password', value: password);
  }
  String formatDate(String dateStr) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
  }
  Future<void> clearCredentials() async {
    await secureStorage.delete(key: 'username');
    await secureStorage.delete(key: 'password');
  }
  Future<void> loadSavedCredentials() async {
    device_info=await getDeviceInfo();
    print(device_info);
    String? savedUsername = await secureStorage.read(key: 'username');
    String? savedPassword = await secureStorage.read(key: 'password');

    if (savedUsername != null && savedPassword != null) {
      _usernameController.text = savedUsername;
      _passwordController.text = savedPassword;

      keepMeSignedIn= true;
      setState(() {});
    }
  }


  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String deviceVersionName = packageInfo.version;
    String deviceModelName = '';
    String deviceManufacturer = '';
    String deviceType = Platform.isAndroid ? 'android' : 'ios';
    String androidOrVendorId = '';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceModelName = androidInfo.model ?? '';
      deviceManufacturer = androidInfo.manufacturer ?? '';
      androidOrVendorId = androidInfo.id ?? ''; // Not IMEI, but unique ID
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceModelName = iosInfo.utsname.machine ?? '';
      deviceManufacturer = 'Apple';
      androidOrVendorId = iosInfo.identifierForVendor ?? '';
    }

    return {
      "device_version_name": deviceVersionName,
      "device_model_name": deviceModelName,
      "device_manufacturer": deviceManufacturer,
      "device_type": deviceType,
      "device_id": androidOrVendorId
    };
  }


  Future<void> _setUser(Map<String, dynamic> result) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user', json.encode(result));
  }
  Future getOSVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    osVersion = "Unknown";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      osVersion = "${androidInfo.brand} ${androidInfo.model} Android ${androidInfo.version.release}";
      //model_name=androidInfo.model;
      // Example: "Android 13"
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      osVersion = "Apple ${iosInfo.utsname.machine} iOS ${iosInfo.systemVersion}"; // Example: "iOS 17.2"
    }


  }
  String? packageName;
  void checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    packageName = packageInfo.packageName;

  }

  Future<String?> getLatestVersion() async {
    final url = Uri.parse(
        "https://play.google.com/store/apps/details?id=$packageName&hl=en");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      RegExp regex = RegExp(r'\[\[\["([0-9]+\.[0-9]+\.[0-9]+)"\]\]');
      var match = regex.firstMatch(response.body);
      if (match != null) {
        return match.group(1); // Extract version number
      }
    }
    return null; // Return null if fetching fails
  }
  Future<void> _login(String username, String password) async {
    final uri = Uri.parse('$login_baseurl$LOGIN');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'username': username,
      'password': password,
      'currLoginOutFlag': 'L',
      'appversion': appVersion,
      'osVersion': osVersion,
    });

    try {
      // 🔁 Check for app update
      final latestVersion = await getLatestVersion();
      if (latestVersion != null && latestVersion != appVersion) {
        _showError('Please update to the latest version');
        _redirectToPlayStore();
        return;
      }

      // 🌐 API Call
      final response = await http.post(uri, headers: headers, body: body);
      print(response.statusCode);
      print(response.body);

      // ✅ Handle success response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!data.containsKey('jwtToken')) {
          _showError(data['message'] ?? 'Invalid credentials or malformed response');
          return;
        }

        final user = data['tmUsers'];
        final prefs = await SharedPreferences.getInstance();

        // 💾 Save user data
        await prefs.setBool("isLoggedIn", true);
        await prefs.setString('UserId', user['userId'].toString());
        await prefs.setString('Username', data['username']);
        await prefs.setString('Token', data['jwtToken']);
        await prefs.setString('osversion', osVersion ?? '');
        _setUser(user);
        keepMeSignedIn == true?
        await saveCredentials(_usernameController.text, _passwordController.text):
        await clearCredentials();

        setState(() {
          prefs.setBool("isLoggedIn", true);


        });

        userRole = await GetUserType(user['lookupDetIdRoleType']);
        await prefs.setString('userRole', userRole ?? '');

        if (!context.mounted) return;

        // 🔐 Redirect
        if (user['floginPwreset'] == 'N') {
          fetchAssignedHCFData();
          _redirectToRoleScreen(userRole,user["bulkDataSaveFlag"]);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPassword(data)),
          );
        }
      } else {
        // ❌ Error handling based on status
        switch (response.statusCode) {
          case 401:
            _showError('Unauthorized: Invalid username or password.');
            break;
          case 500:
            _showError('Server error. Please try again later.');
            break;
          default:
            _showError('Unexpected error (${response.statusCode}): ${response.reasonPhrase}');
        }
      }
    } catch (e) {

      _showError('Login failed: Please Enter Valid Credentials');
    }
  }
  // void _redirectToRoleScreen(String? role,bulk) {
  //   final routeMap = {
  //     'HCF User': AppRoutes.hcf_biowasteScreen,
  //     'CBWT User': AppRoutes.nearby_hcf,
  //   //  'CBWT User': AppRoutes.nearby_hcf,
  //     'CBWT Reception User': AppRoutes.vehicle_screen,
  //
  //     'Disposal User': bulk=='N'?AppRoutes.waste_received_byvehicle: Navigator.push(
  //   context,
  //   MaterialPageRoute(
  //   builder: (_) => DisposalOverallCollection(formattedList),
  //   ),
  //   ),
  //     'Vehicle  User': AppRoutes.vehicle_nearby_hcf,
  //   };
  //
  //   final route = routeMap[role];
  //   if (route != null) {
  //     Navigator.of(context).popAndPushNamed(route);
  //   } else {
  //     _showError('Unknown User !!');
  //   }
  // }
  void _redirectToRoleScreen(String? role, bulk) {
    print('bulk');
    print(bulk);
    if (role == 'Disposal User') {
      if (bulk == 'N') {
        Navigator.of(context).popAndPushNamed(AppRoutes.waste_received_byvehicle);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DisposalOverallCollection(),
          ),
        );
      }
      return;
    }
    // if(role=="CBWT Reception User"){
    //   if (bulk == 'N') {
    //     Navigator.of(context).popAndPushNamed(AppRoutes.vehicle_screen);
    //   } else {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (_) => OverallDataCollection(),
    //       ),
    //     );
    //   }
    //   return;



    final routeMap = {
      'HCF User': AppRoutes.hcf_biowasteScreen,
      'CBWT User': AppRoutes.nearby_hcf,
      'CBWT Reception User': AppRoutes.vehicle_screen,
      'Vehicle  User': AppRoutes.vehicle_nearby_hcf,
    };

    final route = routeMap[role];
    if (route != null) {
      Navigator.of(context).popAndPushNamed(route);
    } else {
      _showError('Unknown User !!');
    }
  }

  List<Map<String, dynamic>> transformResponse(
      List responseList,
      {required int userId}) {
    return responseList.map((item) {
      return {
        "cbwtfRecpDispIds": item["cbwtfRecpDispIds"],
        "totalNoOfBags": item["totalNoOfBags"],
        "totalQuantityBagKg": item["totalQuantityBagKg"],
        "pickupNoOfbag": item["pickupNoOfbag"],
        "pickupTotalQuantityBagCbwtfKg": item["pickupTotalQuantityBagCbwtfKg"],
        "lookupDetIdCategory": 3,
        "userId": userId
      };
    }).toList();
  }
  Future<void> fetchAssignedHCFData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final UserId = prefs.getString('UserId');

      final response = await http.get(
        Uri.parse('${baseurl}${GET_DISPOSAL_DATA}fromDate=${DateTime.now().toString().substring(0,10)}&toDate=${DateTime.now().toString().substring(0,10)}&userId=$UserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },);
      print('${baseurl}${GET_DISPOSAL_DATA}fromDate=${DateTime.now().toString().substring(0,10)}&toDate=${DateTime.now().toString().substring(0,10)}&userId=$UserId');
      print(response.body);
      if (response.statusCode == 200) {
        Map<String,dynamic>value = jsonDecode(response.body);
        List data=value['data']==null?[]:value['data'];
        formattedList=transformResponse(data, userId: int.parse(UserId!));
        print(formattedList);




        setState(() {
          _tableData = data.map((e) => {
            'wasteId':e['hcfWasteId'],
            'date': formatDate(e['assignDateCbwtf']),
            'name': e['vehicleNo'],
            'bags': e['totalNoOfBags'],
            'waste': e['totalQuantityBagKg'],
          }).toList();
          _isLoading = false;
        });
        print(_tableData);
      } else {
        // handle error
        setState(() => _isLoading = false);
      }}
    catch (e) {
      print('Error fetching HCFs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching HCFs: $e'), backgroundColor: Colors.red),
      );
    }}


  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
  Future<String?> GetUserType(id) async {
    setState(() {
      isLoading=true;
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
        '${masterurl}${ROLE_TYPE}$id',
      );

      final response = await http.get(
        url,
        headers: headers,
      );


      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        Map<String,dynamic> userRole=jsonResponse['data'];
        print(userRole['lookupDetDescEn']);
        return userRole['lookupDetDescEn'];


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
    return null;


  }


  void _redirectToPlayStore() async {
    // String packageName = "com.example.myapp"; // Replace with your app's package name
    final playStoreUrl = "https://play.google.com/store/apps/details?id=$packageName";
    if (await canLaunch(playStoreUrl)) {
      await launch(playStoreUrl);
    } else {
      print("Could not open Play Store.");
    }
  }
  @override
  void initState() {
    super.initState();
    checkVersion();

    getOSVersion();
    loadSavedCredentials();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              background,
              fit: BoxFit.cover,
            ),
          ),

          // Login form card
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: SafeArea( // ✅ Fix: respects navigation bar & notch
                top: false, // keep only bottom safe padding
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Image.asset(logo, width: 100),
                        const SizedBox(height: 10),
                        const Text(
                          'Bio Waste App',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Sign In',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Welcome! Enter username & password\n to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // Username
                        AppTextfield(
                          hintText: "Username",
                          controller: _usernameController,
                          prefixIcon: Icons.person_outline_outlined,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter username'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        AppTextfield(
                          controller: _passwordController,
                          prefixIcon: Icons.password,
                          suffixIcon: GestureDetector(
                            onTap: (){
                              setState(() {
                                isobscured=! isobscured;
                              });
                            },
                              child:Icon(Icons.remove_red_eye_outlined,color: isobscured?kPrimaryColor:Colors.grey,)),
                          obscureText: isobscured,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter password'
                              : null,
                          hintText: 'Password',
                        ),

                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                        Row(
                          children: [
                            Checkbox(
                              value: keepMeSignedIn,
                              onChanged: (value) {
                                setState(() => keepMeSignedIn = value!);
                              },
                            ),
                            const Text('Keep me Sign In'),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Sign in button
                        AppButton(
                          text: 'Sign In',
                          onPressed: () {
                            _login(_usernameController.text,
                                _passwordController.text);
                          },
                          isLoading: isLoading,
                          color: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
