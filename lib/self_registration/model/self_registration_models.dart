import 'dart:convert';

/// Model classes for the Self Registration module only.
///
/// [SelfRegistrationRequest]  -> the multipart payload for
///   `masters/users/save-user-temp-survey`.
/// [SelfRegistrationResult]   -> the parsed / classified server response.

/// Immutable payload for the `save-user-temp-survey` endpoint.
///
/// The endpoint is multipart-only and additionally requires a registration
/// document (sent separately as the `imageUpload` file part).
class SelfRegistrationRequest {
  // account
  final String userName;
  final String userFullName;
  final String password;
  final String confirmPassword;
  final String mobileNumber;
  final String emailId;
  final String panCard;

  // hcf
  final String nameOfHcf;
  final String hcfContactNo;
  final String hcfEmailId;
  final String hcfAddress;
  final String pincode;
  final String drRegisterationNo;

  // master ids (already stringified from the selected dropdown rows)
  final String typeOfHcfId; // lookupDetIdTypeOfHcf
  final String divisionId; // lookupDetHierIdDivision
  final String districtId; // lookupDetHierDistrictId
  final String talukaId; // lookupDetHierIdTaluka

  // device
  final String macId;

  const SelfRegistrationRequest({
    required this.userName,
    required this.userFullName,
    required this.password,
    required this.confirmPassword,
    required this.mobileNumber,
    required this.emailId,
    required this.panCard,
    required this.nameOfHcf,
    required this.hcfContactNo,
    required this.hcfEmailId,
    required this.hcfAddress,
    required this.pincode,
    required this.drRegisterationNo,
    required this.typeOfHcfId,
    required this.divisionId,
    required this.districtId,
    required this.talukaId,
    required this.macId,
  });

  /// All fields as strings for the multipart body. Fixed values
  /// (`floginPwreset`, role type, audit ids, `deviceFrom`, …) live here so the
  /// UI never has to know about them.
  Map<String, String> toFields() => {
        'userName': userName.trim(),
        'userFullName': userFullName.trim(),
        'password': password.trim(),
        'confirmPassword': confirmPassword.trim(),
        'mobileNumber': mobileNumber.trim(),
        'emailId': emailId.trim(),
        'floginPwreset': 'Y',
        'lookupDetIdRoleType': '311',
        'status': '1',
        'createdBy': '2',
        'updatedBy': '2',
        'macId': macId,
        'ipAddress': '',
        'deviceFrom': 'M',
        'tempSurveyHcfUser': 'Y',
        'nameofHcf': nameOfHcf.trim(),
        'hcfContactNo': hcfContactNo.trim(),
        'hcfEmailId': hcfEmailId.trim(),
        'hcfAddress': hcfAddress.trim(),
        'panCard': panCard.trim().toUpperCase(),
        'lookupDetHierIdDivision': divisionId,
        'lookupDetHierDistrictId': districtId,
        'lookupDetHierIdTaluka': talukaId,
        'pincode': pincode.trim(),
        'lookupDetIdTypeOfHcf': typeOfHcfId,
        'nameOfHcf': nameOfHcf.trim(),
        'address1': hcfAddress.trim(),
        'hcfOwnerContact': hcfContactNo.trim(),
        'drRegisterationNo': drRegisterationNo.trim(),
      };
}

/// Outcome buckets the UI cares about.
enum SelfRegistrationStatus { success, usernameExists, documentRequired, failed }

/// Parsed + classified response of a self-registration submit.
class SelfRegistrationResult {
  final SelfRegistrationStatus status;

  /// Raw server `message` (may be empty).
  final String message;
  final int? tempUserId;

  const SelfRegistrationResult(
    this.status,
    this.message, {
    this.tempUserId,
  });

  bool get isSuccess => status == SelfRegistrationStatus.success;

  factory SelfRegistrationResult.fromResponse(int statusCode, String body) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      json = const {};
    }

    final bool httpOk = statusCode == 200 || statusCode == 201;
    final String apiStatus = (json['status'] ?? '').toString().toLowerCase();
    final String rawMsg = (json['message'] ?? '').toString();
    final String msg = rawMsg.toLowerCase();

    if (httpOk && apiStatus == 'success') {
      final data = json['data'];
      final int? id = data is Map ? (data['tempUserId'] as int?) : null;
      return SelfRegistrationResult(
        SelfRegistrationStatus.success,
        rawMsg,
        tempUserId: id,
      );
    }

    if (msg.contains('duplicate') ||
        msg.contains('already exists') ||
        msg.contains('user_name')) {
      return SelfRegistrationResult(
          SelfRegistrationStatus.usernameExists, rawMsg);
    }

    if (msg.contains('document is required') ||
        msg.contains('document required')) {
      return SelfRegistrationResult(
          SelfRegistrationStatus.documentRequired, rawMsg);
    }

    return SelfRegistrationResult(SelfRegistrationStatus.failed, rawMsg);
  }
}

/// Existing establishment data returned by the "get user by mobile" lookup that
/// runs right after OTP verification. Every field is optional — a brand-new
/// mobile number yields `null` and the form stays blank.
///
/// UI-ready shape only. The real JSON keys are filled in from the API doc once
/// the backend shares it; [SelfRegistrationPrefill.fromJson] is the single place
/// that mapping will live.
class SelfRegistrationPrefill {
  final int? surveyId;
  final bool flagApprove;

  // person / account
  final String? fullName; // best-guess from hcfOwnerName
  final String? phoneNo;
  final String? emailId;
  final String? panNo;

  // hcf
  final String? nameOfHcf;
  final String? hcfContactNo;
  final String? hcfEmailId;
  final String? address1;
  final String? pincode;

  // master display names (matched to the dropdown rows by name, not id)
  final String? hcfTypeName; // lookupdethcftype
  final String? divisionName;
  final String? districtName;
  final String? talukaName;

  const SelfRegistrationPrefill({
    this.surveyId,
    this.flagApprove = false,
    this.fullName,
    this.phoneNo,
    this.emailId,
    this.panNo,
    this.nameOfHcf,
    this.hcfContactNo,
    this.hcfEmailId,
    this.address1,
    this.pincode,
    this.hcfTypeName,
    this.divisionName,
    this.districtName,
    this.talukaName,
  });

  /// `true` when at least one usable value came back.
  bool get hasData => [
        fullName,
        phoneNo,
        emailId,
        panNo,
        nameOfHcf,
        hcfContactNo,
        hcfEmailId,
        address1,
        pincode,
        hcfTypeName,
        divisionName,
        districtName,
        talukaName,
      ].any((v) => v != null && v.trim().isNotEmpty);

  factory SelfRegistrationPrefill.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      final str = v?.toString().trim() ?? '';
      return str.isEmpty ? null : str;
    }

    return SelfRegistrationPrefill(
      surveyId: json['surveyId'] is int
          ? json['surveyId'] as int
          : int.tryParse('${json['surveyId']}'),
      flagApprove: json['flagApprove'] == true,
      fullName: s(json['hcfOwnerName']),
      phoneNo: s(json['phoneNo']),
      emailId: s(json['emailId']),
      panNo: s(json['panNo']),
      nameOfHcf: s(json['nameOfHcf']),
      hcfContactNo: s(json['hcfOwnerContact']) ?? s(json['phoneNo']),
      hcfEmailId: s(json['hcfOwnerEmail']) ?? s(json['emailId']),
      address1: s(json['address1']),
      pincode: s(json['pincode']),
      hcfTypeName: s(json['lookupdethcftype']),
      divisionName: s(json['divisionName']),
      districtName: s(json['district']),
      talukaName: s(json['taluka']),
    );
  }
}

/// Result of the self-registration send-OTP call
/// (`masters/users/search-registration/by-otp`).
enum SelfRegistrationOtpSendStatus { sent, error }

class SelfRegistrationOtpSendResult {
  final SelfRegistrationOtpSendStatus status;

  /// Raw server `message` (may be empty).
  final String message;

  const SelfRegistrationOtpSendResult(this.status, this.message);

  bool get isSent => status == SelfRegistrationOtpSendStatus.sent;

  /// Success = HTTP 200 + `message == "success"` (mirrors the login OTP flow).
  /// Anything else is an error and carries the server message through.
  factory SelfRegistrationOtpSendResult.fromResponse(
      int statusCode, String body) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(body);
      json = decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      json = const {};
    }

    final rawMsg = (json['message'] ?? '').toString();
    if (statusCode == 200 && rawMsg.toLowerCase().trim() == 'success') {
      return const SelfRegistrationOtpSendResult(
          SelfRegistrationOtpSendStatus.sent, '');
    }
    return SelfRegistrationOtpSendResult(
        SelfRegistrationOtpSendStatus.error, rawMsg);
  }
}

/// Buckets the user-by-mobile search can land in.
enum SelfRegistrationSearchStatus { found, notFound, alreadySubmitted, error }

/// Classified result of `users/search/self-registration/user-by-mobile`.
class SelfRegistrationSearchResult {
  final SelfRegistrationSearchStatus status;
  final String message;
  final SelfRegistrationPrefill? data;

  const SelfRegistrationSearchResult(this.status, this.message, {this.data});

  bool get isFound => status == SelfRegistrationSearchStatus.found;

  factory SelfRegistrationSearchResult.fromResponse(
      int statusCode, String body) {
    // Every real response from this endpoint (found / not-found / already-
    // submitted) is a JSON object. A non-JSON body means the API isn't
    // reachable (server down, Tomcat 404 page, proxy error) — treat that as an
    // error, NOT as "no registration", so an outage can't masquerade as a
    // brand-new applicant.
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return const SelfRegistrationSearchResult(
          SelfRegistrationSearchStatus.error,
          'Unexpected response from server.',
        );
      }
      json = decoded;
    } catch (_) {
      return const SelfRegistrationSearchResult(
        SelfRegistrationSearchStatus.error,
        'Unable to reach the server. Please try again.',
      );
    }

    final apiStatus = (json['status'] ?? '').toString().toLowerCase();
    final rawMsg = (json['message'] ?? '').toString();
    final msg = rawMsg.toLowerCase();

    if (statusCode == 200 && apiStatus == 'success' && json['data'] is Map) {
      return SelfRegistrationSearchResult(
        SelfRegistrationSearchStatus.found,
        rawMsg,
        data: SelfRegistrationPrefill.fromJson(
            Map<String, dynamic>.from(json['data'] as Map)),
      );
    }

    if (statusCode == 409 ||
        msg.contains('under scrutiny') ||
        msg.contains('already submitted')) {
      return SelfRegistrationSearchResult(
        SelfRegistrationSearchStatus.alreadySubmitted,
        rawMsg,
      );
    }

    // Genuine "not found" always carries the fail status + message.
    if (apiStatus == 'fail' &&
        (statusCode == 404 ||
            msg.contains('no registration found') ||
            msg.contains('not found'))) {
      return SelfRegistrationSearchResult(
        SelfRegistrationSearchStatus.notFound,
        rawMsg,
      );
    }

    return SelfRegistrationSearchResult(
      SelfRegistrationSearchStatus.error,
      rawMsg,
    );
  }
}
