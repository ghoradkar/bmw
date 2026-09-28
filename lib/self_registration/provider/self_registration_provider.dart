import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/Global/url.dart';

import 'package:mpcb_bio_waste/self_registration/model/self_registration_models.dart';


class SelfRegistrationProvider extends ChangeNotifier {
  SelfRegistrationProvider({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Allowed registration-document types / size (UI-side enforced).
  static const List<String> allowedDocExt = ['jpg', 'jpeg', 'png'];
  static const int maxDocBytes = 25 * 1024 * 1024;

  // ---- busy flags -----------------------------------------------------------
  bool _loadingMasters = false;
  bool _submitting = false;
  bool get loadingMasters => _loadingMasters;
  bool get submitting => _submitting;

  // ---- one-shot error channel for the UI (snackbars) -----------------------
  String? _error;
  String? get error => _error;

  /// Reads and clears the pending error without notifying (call from a listener).
  String? takeError() {
    final e = _error;
    _error = null;
    return e;
  }

  // ---- device -------------------------------------------------------------
  String _macId = '';

  // ---- master data (raw rows for validatedApiDropdown) --------------------
  List<Map<String, dynamic>> hcfTypes = [];
  List<Map<String, dynamic>> divisions = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> talukas = [];

  Map<String, dynamic>? selectedHcfType;
  Map<String, dynamic>? selectedDivision;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedTaluka;

  bool get hasAllSelections =>
      selectedHcfType != null &&
      selectedDivision != null &&
      selectedDistrict != null &&
      selectedTaluka != null;

  // ---- registration document --------------------------------------------
  PlatformFile? pickedDoc;

  // ---- lifecycle --------------------------------------------------------

  Future<void> init() async {
    await Future.wait([_loadHcfTypes(), _loadDeviceId()]);
  }

  /// Sends a one-time password to [mobile] for the self-registration flow.
  /// `POST {masterurl}users/search-registration/by-otp`, raw JSON `{mobileNo}`.
  /// Success = HTTP 200 + `message == "success"`.
  static Future<SelfRegistrationOtpSendResult> sendOtp(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse('$masterurl$SEND_OTP_SELF_REGISTRATION'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNo': mobile.trim()}),
      );
      debugPrint(
          'SELF REG SEND OTP ${response.statusCode} -> ${response.body}');
      return SelfRegistrationOtpSendResult.fromResponse(
        response.statusCode,
        response.body,
      );
    } catch (e) {
      debugPrint('SELF REG SEND OTP ERROR -> $e');
      return SelfRegistrationOtpSendResult(
        SelfRegistrationOtpSendStatus.error,
        e.toString(),
      );
    }
  }

  /// One-off search for an existing establishment by [mobile], run by the entry
  /// flow right after the OTP is entered (before the form screen opens, so the
  /// "already submitted" case can be handled without flashing the form).
  ///
  /// This call also *verifies* [otp] — there is no separate verify-OTP endpoint
  /// for self-registration; a valid OTP returns the registration data in one
  /// step.
  ///
  /// Static + own client: the form screen keeps its own provider instance.
  static Future<SelfRegistrationSearchResult> searchByMobile(
      String mobile, String otp) async {
    final client = http.Client();
    try {
      // Per the API doc: GET with `mobileNumber` + `otp` sent as form-data body
      // fields (not query params). Runs against the configured test env
      // (`masterurl`).
      final req = http.MultipartRequest(
        'GET',
        Uri.parse('$masterurl$SEARCH_SELF_REGISTRATION'),
      );
      req.fields['mobileNumber'] = mobile.trim();
      req.fields['otp'] = otp.trim();
      final response = await http.Response.fromStream(await client.send(req));
      debugPrint(
          'SELF REG SEARCH ${response.statusCode} -> ${response.body}');
      return SelfRegistrationSearchResult.fromResponse(
        response.statusCode,
        response.body,
      );
    } catch (e) {
      debugPrint('SELF REG SEARCH ERROR -> $e');
      return SelfRegistrationSearchResult(
        SelfRegistrationSearchStatus.error,
        e.toString(),
      );
    } finally {
      client.close();
    }
  }

  Future<void> _loadDeviceId() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        _macId = (await info.androidInfo).id;
      } else if (Platform.isIOS) {
        _macId = (await info.iosInfo).identifierForVendor ?? '';
      }
    } catch (_) {
      // Non-fatal: submit still works with an empty macId.
    }
  }

  Future<void> _loadHcfTypes() async {
    _loadingMasters = true;
    notifyListeners();
    try {
      final res = await _client.get(Uri.parse('$masterurl$HCF_TYPE'));
      if (res.statusCode != 200) {
        throw 'Failed to fetch HCF type';
      }
      final decoded = jsonDecode(res.body);
      hcfTypes = List<Map<String, dynamic>>.from(decoded['data'] ?? const []);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMasters = false;
      notifyListeners();
    }
  }

  /// Fetch + dedupe division / district / taluka for [pincode].
  ///
  /// When [divisionName] / [districtName] / [talukaName] are given (prefill
  /// flow) the matching rows are pre-selected instead of the first entry.
  Future<void> loadLocation(
    String pincode, {
    String? divisionName,
    String? districtName,
    String? talukaName,
  }) async {
    _loadingMasters = true;
    notifyListeners();
    try {
      final res = await _client.get(
        Uri.parse('$masterurl$GET_DATA_BY_PINCODE${pincode.trim()}'),
      );
      if (res.statusCode != 200) {
        throw 'Failed to fetch address';
      }
      final decoded = jsonDecode(res.body);
      final rows =
          List<Map<String, dynamic>>.from(decoded['data'] ?? const []);

      final divMap = <String, Map<String, dynamic>>{};
      final distMap = <String, Map<String, dynamic>>{};
      final talMap = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        if (r['divId'] != null) divMap['${r['divId']}'] = r;
        if (r['distId'] != null) distMap['${r['distId']}'] = r;
        if (r['talukaId'] != null) talMap['${r['talukaId']}'] = r;
      }

      divisions = divMap.values.toList();
      districts = distMap.values.toList();
      talukas = talMap.values.toList();

      selectedDivision = _matchByName(divisions, 'divName', divisionName) ??
          (divisions.isNotEmpty ? divisions.first : null);
      selectedDistrict = _matchByName(districts, 'distName', districtName) ??
          (districts.isNotEmpty ? districts.first : null);
      selectedTaluka = _matchByName(talukas, 'talukaName', talukaName) ??
          (talukas.isNotEmpty ? talukas.first : null);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMasters = false;
      notifyListeners();
    }
  }

  /// Case-insensitive, whitespace-tolerant name match (the survey returns
  /// display names like `"Group A - Mumbai Division\r\n"`).
  Map<String, dynamic>? _matchByName(
    List<Map<String, dynamic>> rows,
    String key,
    String? name,
  ) {
    final target = name?.trim().toLowerCase();
    if (target == null || target.isEmpty) return null;
    for (final r in rows) {
      if ('${r[key]}'.trim().toLowerCase() == target) return r;
    }
    return null;
  }

  // ---- selections -----------------------------------------------------

  void selectHcfType(Map<String, dynamic>? v) {
    selectedHcfType = v;
    notifyListeners();
  }

  /// Prefill helper: select the HCF-type row whose name matches [name] (no-op if
  /// the list isn't loaded yet or nothing matches).
  void selectHcfTypeByName(String? name) {
    final m = _matchByName(hcfTypes, 'lookupDetDescEn', name);
    if (m != null) {
      selectedHcfType = m;
      notifyListeners();
    }
  }

  void selectDivision(Map<String, dynamic>? v) {
    selectedDivision = v;
    notifyListeners();
  }

  void selectDistrict(Map<String, dynamic>? v) {
    selectedDistrict = v;
    notifyListeners();
  }

  void selectTaluka(Map<String, dynamic>? v) {
    selectedTaluka = v;
    notifyListeners();
  }

  // ---- document ------------------------------------------------------

  /// Validates [file] and stores it. Returns a localization key to show on
  /// failure, or `null` on success.
  String? acceptDocument(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    if (!allowedDocExt.contains(ext)) return 'reg_doc_format_invalid';
    if (file.size > maxDocBytes) return 'reg_doc_too_large';
    if (file.path == null) return 'self_reg_failed';
    pickedDoc = file;
    notifyListeners();
    return null;
  }

  void removeDocument() {
    pickedDoc = null;
    notifyListeners();
  }

  // ---- submit ------------------------------------------------------

  /// Assembles the request from the widget's text values + current selections.
  SelfRegistrationRequest buildRequest({
    required String userName,
    required String userFullName,
    required String password,
    required String confirmPassword,
    required String mobileNumber,
    required String emailId,
    required String panCard,
    required String nameOfHcf,
    required String hcfContactNo,
    required String hcfEmailId,
    required String hcfAddress,
    required String pincode,
    required String drRegisterationNo,
  }) {
    return SelfRegistrationRequest(
      userName: userName,
      userFullName: userFullName,
      password: password,
      confirmPassword: confirmPassword,
      mobileNumber: mobileNumber,
      emailId: emailId,
      panCard: panCard,
      nameOfHcf: nameOfHcf,
      hcfContactNo: hcfContactNo,
      hcfEmailId: hcfEmailId,
      hcfAddress: hcfAddress,
      pincode: pincode,
      drRegisterationNo: drRegisterationNo,
      typeOfHcfId: '${selectedHcfType?['lookupDetId'] ?? ''}',
      divisionId: '${selectedDivision?['divId'] ?? ''}',
      districtId: '${selectedDistrict?['distId'] ?? ''}',
      talukaId: '${selectedTaluka?['talukaId'] ?? ''}',
      macId: _macId,
    );
  }

  /// Multipart POST. Returns `null` if there is no document attached.
  /// [documentPath] is sent as the mandatory `imageUpload` file part.
  Future<SelfRegistrationResult?> submit(
      SelfRegistrationRequest request) async {
    final path = pickedDoc?.path;
    if (path == null) return null;

    _submitting = true;
    notifyListeners();
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$masterurl$SELF_REGISTRATION'),
      );
      req.fields.addAll(request.toFields());
      req.files.add(await http.MultipartFile.fromPath('imageUpload', path));

      debugPrint('SELF REGISTRATION BODY -> ${request.toFields()}');

      final response = await http.Response.fromStream(await req.send());
      debugPrint(
          'SELF REGISTRATION ${response.statusCode} -> ${response.body}');

      return SelfRegistrationResult.fromResponse(
        response.statusCode,
        response.body,
      );
    } catch (e) {
      debugPrint('SELF REGISTRATION ERROR -> $e');
      return const SelfRegistrationResult(SelfRegistrationStatus.failed, '');
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Clears selections + location lists + document (keeps the HCF-type list).
  void resetAfterSuccess() {
    selectedHcfType = null;
    selectedDivision = null;
    selectedDistrict = null;
    selectedTaluka = null;
    divisions = [];
    districts = [];
    talukas = [];
    pickedDoc = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
