import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpcb_bio_waste/Global/app_button.dart';
import 'package:mpcb_bio_waste/Global/app_dialog.dart';
import 'package:mpcb_bio_waste/Global/app_textfield.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'dart:convert';

import 'package:mpcb_bio_waste/Global/images.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/authentication/new_hcf_registration.dart';
import 'package:mpcb_bio_waste/authentication/otp_entry_dialog.dart';
import 'package:mpcb_bio_waste/homeScreen.dart';
import 'package:mpcb_bio_waste/self_registration/view/self_registration_otp_flow.dart';
import 'package:mpcb_bio_waste/self_registration/view/self_registration_status.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CBWTF_Disposal/disposal_overall_colection.dart';
import '../CBWTF_Reception/overall_Data_collection.dart';
import '../Global/app_routes.dart';
import '../Localization/app_localization.dart';

import '../localization/provider.dart';
import 'forget_password.dart';

class LoginScreen extends StatefulWidget {
  // final String reset;

  const LoginScreen({super.key});
  // const LoginScreen(this.reset, {super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  /// 'otp' or 'username' — which sign-in tab is active. Opens on 'otp'.
  String _loginMode = 'otp';

  bool keepMeSignedIn = true;
  bool isLoading = false;
  String? userRole;
  bool isobscured = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, dynamic>> formattedList = [];

  String? osVersion;
  final secureStorage = FlutterSecureStorage();
  Map<String, dynamic> device_info = {};

  // ---------------- Information banner (auto-scrolling) ----------------
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBanner = 0;

  // Titles/descriptions are localization keys resolved at build time so the
  // banner follows the selected language (English / Marathi).
  final List<Map<String, dynamic>> _banners = const [
    {
      'titleKey': 'banner_1_title',
      'descKey': 'banner_1_desc',
      'icon': Icons.campaign_outlined,
    },
    {
      'titleKey': 'banner_2_title',
      'descKey': 'banner_2_desc',
      'icon': Icons.app_registration_outlined,
    },
    {
      'titleKey': 'banner_3_title',
      'descKey': 'banner_3_desc',
      'icon': Icons.check_circle_outline,
    },
    {
      'titleKey': 'banner_4_title',
      'descKey': 'banner_4_desc',
      'icon': Icons.how_to_reg_outlined,
    },
    {
      'titleKey': 'banner_5_title',
      'descKey': 'banner_5_desc',
      'icon': Icons.recycling_outlined,
    },
    {
      'titleKey': 'banner_6_title',
      'descKey': 'banner_6_desc',
      'icon': Icons.smartphone_outlined,
    },
  ];

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_bannerController.hasClients) return;
      int nextPage = _currentBanner + 1;
      if (nextPage >= _banners.length) nextPage = 0;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
  }

  void _resumeBannerTimer() {
    if (_bannerTimer != null) return;
    _startBannerTimer();
  }

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
    device_info = await getDeviceInfo();
    print(device_info);
    String? savedUsername = await secureStorage.read(key: 'username');
    String? savedPassword = await secureStorage.read(key: 'password');

    if (savedUsername != null && savedPassword != null) {
      _usernameController.text = savedUsername;
      _passwordController.text = savedPassword;

      keepMeSignedIn = true;
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
      "device_id": androidOrVendorId,
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
      osVersion =
          "${androidInfo.brand} ${androidInfo.model} Android ${androidInfo.version.release}";
      //model_name=androidInfo.model;
      // Example: "Android 13"
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      osVersion =
          "Apple ${iosInfo.utsname.machine} iOS ${iosInfo.systemVersion}"; // Example: "iOS 17.2"
    }
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
    print(uri);
    print(
      jsonEncode({
        'username': username,
        'password': password,
        'currLoginOutFlag': 'L',
        'appversion': appVersion,
        'osVersion': osVersion,
      }),
    );

    try {
      // 🌐 API Call
      final response = await http.post(uri, headers: headers, body: body);
      print(response.statusCode);
      print(response.body);

      // ✅ Handle success response
      if (response.statusCode == 200) {
        print('h');
        final data = jsonDecode(response.body);

        if (!data.containsKey('jwtToken')) {
          _showError(
            data['message'] ?? 'Invalid credentials or malformed response',
          );
          return;
        }
        print('su');

        await _handleAuthSuccess(Map<String, dynamic>.from(data));
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
            _showError(
              'Unexpected error (${response.statusCode}): ${response.reasonPhrase}',
            );
        }
      }
    } catch (e) {
      _showError('Login failed: Please Enter Valid Credentials');
    }
  }

  /// Shared post-login handling for both password login and OTP login.
  /// [data] is the auth response: top-level `jwtToken` + `tmUsers` object.
  ///
  /// [skipPasswordReset] — OTP login skips the first-login password-reset
  /// detour and goes straight to the role dashboard.
  Future<void> _handleAuthSuccess(
    Map<String, dynamic> data, {
    bool skipPasswordReset = false,
  }) async {
    final user = data['tmUsers'];
    final prefs = await SharedPreferences.getInstance();

    // First-login users must reset their password before a session is
    // persisted; otherwise killing the app on the reset screen would let
    // the splash screen open the dashboard on next launch.
    final bool mustResetPassword =
        !skipPasswordReset && user['firstLogin'] == null;

    // 💾 Save user data (Token/UserId are needed by the reset-password API)
    await prefs.setBool("isLoggedIn", !mustResetPassword);
    await prefs.setString('UserId', user['userId'].toString());
    await prefs.setString(
      'username',
      user['userName'] ?? data['username'] ?? '',
    );
    await prefs.setString('email', user['emailId'] ?? '');
    await prefs.setString('Token', data['jwtToken']);
    await prefs.setString('osversion', osVersion ?? '');
    _setUser(user);

    userRole = await GetUserType(user['lookupDetIdRoleType']);
    if (mustResetPassword) {
      await prefs.remove('userRole');
    } else {
      await prefs.setString('userRole', userRole ?? '');
    }

    if (!context.mounted) return;

    // 🔐 Redirect
    final bool isTempSurveyUser = user['tempSurveyHcfUser'] == 'Y';

    // if (!skipPasswordReset && user['floginPwreset'] != 'N') {
    if (mustResetPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
      );
    } else if (isTempSurveyUser && !_isKnownRole(userRole)) {
      // Self-registered user still awaiting scrutiny / role assignment.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SelfRegistrationStatusScreen(),
        ),
      );
    } else {
      fetchAssignedHCFData();
      _redirectToRoleScreen(userRole, user["bulkDataSaveFlag"]);
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
  bool _isKnownRole(String? role) => const {
    'HCF User',
    'CBWT Assign User',
    'CBWT Reception User',
    'Vehicle  User',
    'Disposal User',
  }.contains(role);

  void _redirectToRoleScreen(String? role, bulk) {
    print('bulk');
    print(bulk);
    if (role == 'Disposal User') {
      if (bulk == 'N') {
        Navigator.of(
          context,
        ).popAndPushNamed(AppRoutes.waste_received_byvehicle);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DisposalOverallCollection()),
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
      'CBWT Assign User': AppRoutes.nearby_hcf,
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
    List responseList, {
    required int userId,
  }) {
    return responseList.map((item) {
      return {
        "cbwtfRecpDispIds": item["cbwtfRecpDispIds"],
        "totalNoOfBags": item["totalNoOfBags"],
        "totalQuantityBagKg": item["totalQuantityBagKg"],
        "pickupNoOfbag": item["pickupNoOfbag"],
        "pickupTotalQuantityBagCbwtfKg": item["pickupTotalQuantityBagCbwtfKg"],
        "lookupDetIdCategory": 3,
        "userId": userId,
      };
    }).toList();
  }

  Future<void> fetchAssignedHCFData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';
      final UserId = prefs.getString('UserId');

      final response = await http.get(
        Uri.parse(
          '${baseurl}${GET_DISPOSAL_DATA}fromDate=${DateTime.now().toString().substring(0, 10)}&toDate=${DateTime.now().toString().substring(0, 10)}&userId=$UserId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
        '${baseurl}${GET_DISPOSAL_DATA}fromDate=${DateTime.now().toString().substring(0, 10)}&toDate=${DateTime.now().toString().substring(0, 10)}&userId=$UserId',
      );
      print(response.body);
      if (response.statusCode == 200) {
        Map<String, dynamic> value = jsonDecode(response.body);
        List data = value['data'] == null ? [] : value['data'];
        formattedList = transformResponse(data, userId: int.parse(UserId!));
        print(formattedList);

        setState(() {
          _tableData =
              data
                  .map(
                    (e) => {
                      'wasteId': e['hcfWasteId'],
                      'date': formatDate(e['assignDateCbwtf']),
                      'name': e['vehicleNo'],
                      'bags': e['totalNoOfBags'],
                      'waste': e['totalQuantityBagKg'],
                    },
                  )
                  .toList();
          _isLoading = false;
        });
        print(_tableData);
      } else {
        // handle error
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching HCFs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching HCFs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> GetUserType(id) async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('Token');
    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json ; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('${masterurl}${ROLE_TYPE}$id');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        Map<String, dynamic> userRole = jsonResponse['data'];
        print('userRole');
        print(userRole['lookupDetDescEn']);
        return userRole['lookupDetDescEn'];
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
    return null;
  }

  // ---------------- Information banner UI ----------------

  Widget _buildInformationBanner(AppLocalizations t) {
    // Grow the fixed banner area with the (clamped) font scale so its text
    // can't overflow when the device font size is turned up.
    final double textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
    return Column(
      children: [
        SizedBox(
          height: 150 * textScale,
          child: Listener(
            onPointerDown: (_) => _pauseBannerTimer(),
            onPointerUp: (_) => _resumeBannerTimer(),
            onPointerCancel: (_) => _resumeBannerTimer(),
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _banners.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() => _currentBanner = index);
              },
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return _buildSingleBanner(
                  title: t.translate(banner['titleKey'] as String),
                  description: t.translate(banner['descKey'] as String),
                  icon: banner['icon'] as IconData,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final bool isSelected = _currentBanner == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF1597D0) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSingleBanner({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FFF7),
        border: Border.all(color: const Color(0xFF43D85A), width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 60, child: Center(child: _buildBannerIcon(icon))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF149C22),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerIcon(IconData icon) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(50, 50),
            painter: _ScallopedCirclePainter(),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE7E7E7),
            ),
            child: Icon(icon, color: const Color(0xFF4A3942), size: 22),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getOSVersion();
    loadSavedCredentials();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // ---------------- Sign-in mode toggle + OTP tab ----------------

  void _switchMode(String mode) {
    if (_loginMode == mode) return;
    setState(() {
      _loginMode = mode;
      _usernameController.clear();
      _passwordController.clear();
      _mobileController.clear();
      _formKey.currentState?.reset();
    });
  }

  Widget _buildSegmentedToggle(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _segment(t.translate('sign_in_with_otp'), 'otp')),
          Expanded(
            child: _segment(t.translate('sign_in_with_username'), 'username'),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, String mode) {
    final bool selected = _loginMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient:
              selected
                  ? const LinearGradient(
                    colors: [Color(0xFF35B3DE), Color(0xFF1189C6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                  : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF1189C6).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _otpMobileField(AppLocalizations t) {
    // Mirrors AppTextfield's look (used by the Username field) so both tabs
    // match; adds the non-editable "+91 " prefix and digits-only input.
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: _mobileController,
      keyboardType: TextInputType.number,
      cursorColor: kBlackColor,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.black87, fontSize: 12),
      decoration: InputDecoration(
        counterText: '',
        labelText: t.translate('mobile_no'),
        hintText: t.translate('mobile_no'),
        labelStyle: const TextStyle(fontSize: 13),
        hintStyle: const TextStyle(fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: kWhiteColor,
        prefixIcon: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: const Icon(Icons.phone_android, color: Colors.white),
        ),
        prefixText: '+91 ',
        prefixStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimaryDarkColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator:
          (v) =>
              RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : t.translate('enter_valid_mobile'),
    );
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    final mobile = _mobileController.text.trim();

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$login_baseurl$LOGIN_BY_MOBILE'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNo': mobile}),
      );
      debugPrint('LOGIN-BY-MOBILE ${response.statusCode} -> ${response.body}');

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        _showError(t.translate('otp_send_failed'));
        return;
      }
      final msg = (body['message'] ?? '').toString();

      if (response.statusCode == 200 && msg.toLowerCase() == 'success') {
        if (mounted) await _openOtpDialog(mobile);
        return;
      }
      if (msg.toLowerCase().contains('user not found')) {
        _showError(t.translate('mobile_not_registered'));
        return;
      }
      _showError(msg.isNotEmpty ? msg : t.translate('otp_send_failed'));
    } catch (e) {
      debugPrint('LOGIN-BY-MOBILE ERROR -> $e');
      _showError(t.translate('otp_send_failed'));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openOtpDialog(String mobile) async {
    final t = AppLocalizations.of(context);
    final authData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => OtpEntryDialog(mobile: mobile, osVersion: osVersion ?? ''),
    );

    if (authData == null || !mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => SuccessDialog(
            message: t.translate('otp_verified'),
            buttonText: t.translate('ok'),
          ),
    );

    if (!mounted) return;
    await _handleAuthSuccess(authData, skipPasswordReset: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    // Keep the login card close to the design when the device font size is
    // turned up — a large system scale otherwise overflows the fixed-height
    // card. Content still scrolls. Presentational only.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Scaffold(
        body: Stack(
          children: [
            // Background image
            SizedBox.expand(child: Image.asset(background, fit: BoxFit.cover)),

            // Login form card
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: SafeArea(
                  // ✅ Fix: respects navigation bar & notch
                  top: false, // keep only bottom safe padding
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(15, 36, 15, 0),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Image.asset(secondLog, width: 100),
                              Image.asset(logo, width: 126),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'MPCB-BMW Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.translate('sign_in'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildSegmentedToggle(t),
                          const SizedBox(height: 20),

                          if (_loginMode == 'otp') ...[
                            _otpMobileField(t),
                            const SizedBox(height: 20),
                          ] else ...[
                            AppTextfield(
                              hintText: t.translate('username'),
                              controller: _usernameController,
                              prefixIcon: Icons.person_outline_outlined,
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Please enter username'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            AppTextfield(
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter password'
                                          : null,
                              hintText: t.translate('password'),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // TextButton(
                                //   onPressed: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder:
                                //             (context) => NewHCFRegisterScreen(),
                                //       ),
                                //     );
                                //   },
                                //   child: Text(
                                //     t.translate('new_hcf'),
                                //     style: const TextStyle(
                                //       color: Color(0xFF2196F3),
                                //       fontSize: 11,
                                //     ),
                                //   ),
                                // ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ResetPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    t.translate('forgot_password'),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              text:
                                  _loginMode == 'otp'
                                      ? t.translate('send_otp')
                                      : t.translate('sign_in'),
                              onPressed: () {
                                if (_loginMode == 'otp') {
                                  _sendOtp();
                                } else {
                                  _login(
                                    _usernameController.text,
                                    _passwordController.text,
                                  );
                                }
                              },
                              isLoading: isLoading,
                              color: Colors.deepOrange,
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 18,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              text: t.translate('self_registration'),
                              onPressed:
                                  () => openSelfRegistrationFlow(context),
                              color: const Color(0xFF1597D0),
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 18,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: 'mr',
                                activeColor: Colors.deepOrange,
                                groupValue: langProvider.locale.languageCode,
                                onChanged: (value) {
                                  context
                                      .read<LanguageProvider>()
                                      .changeLanguage(value!);
                                },
                              ),
                              const Text('मराठी'),

                              SizedBox(width: 30),

                              Radio<String>(
                                value: 'en',
                                activeColor: Colors.deepOrange,
                                groupValue: langProvider.locale.languageCode,
                                onChanged: (value) {
                                  context
                                      .read<LanguageProvider>()
                                      .changeLanguage(value!);
                                },
                              ),
                              const Text('English'),
                            ],
                          ),
                          SizedBox(height: 10),
                          _buildInformationBanner(t),
                          SizedBox(height: 10),
                          Text(
                            'Version $appVersion ',
                            style: TextStyle(fontSize: 11),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scalloped (flower-edge) green circle behind the banner icon.
// ---------------------------------------------------------------------------
class _ScallopedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = const Color(0xFF38D56A)
          ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = size.width / 2;
    final Path path = Path();
    const int points = 24;

    for (int i = 0; i < points; i++) {
      final double angle = (2 * pi * i) / points - pi / 2;
      final double radius = i.isEven ? outerRadius : outerRadius - 4;
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
