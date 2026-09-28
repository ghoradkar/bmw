import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import 'package:mpcb_bio_waste/Global/app_bar.dart';
import 'package:mpcb_bio_waste/Global/app_button.dart';
import 'package:mpcb_bio_waste/Global/app_dialog.dart';
import 'package:mpcb_bio_waste/Global/app_dropdown.dart';
import 'package:mpcb_bio_waste/Global/app_textfield.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:mpcb_bio_waste/Global/size_config.dart';
import 'package:mpcb_bio_waste/Localization/app_localization.dart';
import 'package:mpcb_bio_waste/localization/provider.dart';
import 'package:mpcb_bio_waste/network/network_aware.dart';
import 'package:mpcb_bio_waste/network/network_status.dart';
import 'package:mpcb_bio_waste/network/offline.dart';

import 'package:mpcb_bio_waste/self_registration/model/self_registration_models.dart';
import 'package:mpcb_bio_waste/self_registration/provider/self_registration_provider.dart';

/// Self Registration screen (UI only).
///
/// All networking + module state lives in [SelfRegistrationProvider] /
/// [SelfRegistrationApi]; this widget owns nothing but the form controllers.
class SelfRegistration extends StatelessWidget {
  const SelfRegistration({super.key, this.verifiedMobile, this.prefill});

  /// OTP-verified mobile number handed over from the entry flow. Pre-fills the
  /// "Mobile Number" field when an existing survey record was found, or the
  /// "HCF's Contact Number" field for a brand-new applicant (search 404). Still
  /// editable either way.
  final String? verifiedMobile;

  /// Existing establishment data from the user-by-mobile search; `null` for a
  /// brand-new applicant (form opens blank).
  final SelfRegistrationPrefill? prefill;

  @override
  Widget build(BuildContext context) {
    // Cap an extreme "maximum font size" device setting so the long form stays
    // laid out as designed (it still scrolls). Presentational only.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: StreamProvider<NetworkStatus>(
        create:
            (context) => NetworkStatusService().networkStatusController.stream,
        initialData: NetworkStatus.Online,
        child: ChangeNotifierProvider<SelfRegistrationProvider>(
          create: (_) => SelfRegistrationProvider()..init(),
          child: NetworkAwareWidget(
            onlineChild: _SelfRegistrationForm(
              verifiedMobile: verifiedMobile,
              prefill: prefill,
            ),
            offlineChild: Offline(),
          ),
        ),
      ),
    );
  }
}

class _SelfRegistrationForm extends StatefulWidget {
  const _SelfRegistrationForm({this.verifiedMobile, this.prefill});

  final String? verifiedMobile;
  final SelfRegistrationPrefill? prefill;

  @override
  State<_SelfRegistrationForm> createState() => _SelfRegistrationFormState();
}

class _SelfRegistrationFormState extends State<_SelfRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // account fields
  final fullNameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final userEmailCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // hcf fields
  final hcfNameCtrl = TextEditingController();
  final hcfContactCtrl = TextEditingController();
  final hcfEmailCtrl = TextEditingController();
  final hcfAddressCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  final drRegNoCtrl = TextEditingController();

  final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*[0-9@!#\$_]).{8,}$');

  late final SelfRegistrationProvider _provider;

  bool _prefillMastersApplied = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<SelfRegistrationProvider>();
    _provider.addListener(_onProviderChanged);
    _applyPrefillText();
    // Masters may already be loaded by the time the listener attaches.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeApplyPrefillMasters(),
    );
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
    fullNameCtrl,
    mobileCtrl,
    userEmailCtrl,
    panCtrl,
    usernameCtrl,
    passwordCtrl,
    confirmPassCtrl,
    hcfNameCtrl,
    hcfContactCtrl,
    hcfEmailCtrl,
    hcfAddressCtrl,
    pincodeCtrl,
    drRegNoCtrl,
  ];

  /// Surface any queued provider error as a snackbar, and retry the dropdown
  /// side of the prefill once the master lists have arrived.
  void _onProviderChanged() {
    final err = _provider.takeError();
    if (err != null && mounted) _showError(err);
    _maybeApplyPrefillMasters();
  }

  /// Text fields — no master data needed, applied straight away.
  void _applyPrefillText() {
    void set(TextEditingController c, String? v) {
      if (v != null && v.trim().isNotEmpty) c.text = v.trim();
    }

    final pf = widget.prefill;
    if (pf != null) {
      set(fullNameCtrl, pf.fullName);
      set(userEmailCtrl, pf.emailId);
      set(panCtrl, pf.panNo);
      set(hcfNameCtrl, pf.nameOfHcf);
      set(hcfContactCtrl, pf.hcfContactNo);
      set(hcfEmailCtrl, pf.hcfEmailId);
      set(hcfAddressCtrl, pf.address1);
      if (RegExp(r'^\d{6}$').hasMatch(pf.pincode ?? '')) {
        set(pincodeCtrl, pf.pincode);
      }
      set(mobileCtrl, pf.phoneNo);
    }

    final verified = widget.verifiedMobile;
    if (verified != null && verified.trim().isNotEmpty) {
      if (pf == null) {
        // Brand-new applicant (search returned 404 "No registration found"):
        // the OTP-verified number is the HCF's contact number, not the login
        // user's mobile — the user enters "Mobile Number" themselves.
        hcfContactCtrl.text = verified.trim();
      } else {
        // Existing survey record: the verified number wins over any looked-up
        // phone for the "Mobile Number" field.
        mobileCtrl.text = verified.trim();
      }
    }
  }

  /// Dropdowns — need the master lists first; runs once they're available.
  void _maybeApplyPrefillMasters() {
    if (_prefillMastersApplied) return;
    final pf = widget.prefill;
    if (pf == null || _provider.hcfTypes.isEmpty) return;
    _prefillMastersApplied = true;

    _provider.selectHcfTypeByName(pf.hcfTypeName);

    if (RegExp(r'^\d{6}$').hasMatch(pf.pincode ?? '')) {
      _provider.loadLocation(
        pf.pincode!,
        divisionName: pf.divisionName,
        districtName: pf.districtName,
        talukaName: pf.talukaName,
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  /* ---------------- REGISTRATION DOCUMENT ---------------- */

  Future<void> _pickDocument(AppLocalizations t) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: SelfRegistrationProvider.allowedDocExt,
      );
      if (result == null || result.files.isEmpty) return;
      final errKey = _provider.acceptDocument(result.files.first);
      if (errKey != null) _showError(t.translate(errKey));
    } catch (_) {
      _showError(t.translate('self_reg_failed'));
    }
  }

  Future<void> _previewDocument() async {
    final path = _provider.pickedDoc?.path;
    if (path != null) await OpenFile.open(path);
  }

  String _humanSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  /* ---------------- SUBMIT ---------------- */

  Future<void> _submit(AppLocalizations t) async {
    final p = _provider;

    if (!_formKey.currentState!.validate()) {
      _showError(t.translate('fix_validation_errors'));
      return;
    }
    if (!p.hasAllSelections) {
      _showError(t.translate('select_location_details'));
      return;
    }
    if (p.pickedDoc?.path == null) {
      _showError(t.translate('reg_doc_required'));
      return;
    }

    final request = p.buildRequest(
      userName: usernameCtrl.text.trim(),
      userFullName: fullNameCtrl.text.trim(),
      password: passwordCtrl.text.trim(),
      confirmPassword: confirmPassCtrl.text.trim(),
      mobileNumber: mobileCtrl.text.trim(),
      emailId: userEmailCtrl.text.trim(),
      panCard: panCtrl.text.trim(),
      nameOfHcf: hcfNameCtrl.text.trim(),
      hcfContactNo: hcfContactCtrl.text.trim(),
      hcfEmailId: hcfEmailCtrl.text.trim(),
      hcfAddress: hcfAddressCtrl.text.trim(),
      pincode: pincodeCtrl.text.trim(),
      drRegisterationNo: drRegNoCtrl.text.trim(),
    );

    final result = await p.submit(request);
    if (!mounted || result == null) return;

    switch (result.status) {
      case SelfRegistrationStatus.success:
        _clearForm();
        p.resetAfterSuccess();
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: SuccessDialog(
                  buttonText: t.translate('ok'),
                  message: t.translate('self_reg_success'),
                  onOk: () => Navigator.pop(context),
                ),
              ),
        );
        break;
      case SelfRegistrationStatus.usernameExists:
        _showError(t.translate('username_exists'));
        break;
      case SelfRegistrationStatus.documentRequired:
        _showError(t.translate('reg_doc_required'));
        break;
      case SelfRegistrationStatus.failed:
        _showError(
          result.message.isNotEmpty
              ? result.message
              : t.translate('self_reg_failed'),
        );
        break;
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    for (final c in _allControllers) {
      c.clear();
    }
  }

  void _onReset() {
    _clearForm();
    _provider.resetAfterSuccess();
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    context.watch<LanguageProvider>();
    final p = context.watch<SelfRegistrationProvider>();

    return Scaffold(
      backgroundColor: kWhiteColor,
      body: Stack(
        children: [
          mAppBar(
            scTitle: t.translate('self_registration'),
            centerTile: true,
            showLeading: true,
            onLeadingIconClick: () => Navigator.pop(context),
          ),
          Positioned(
            top: responsiveHeight(100),
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child:
                        p.loadingMasters
                            ? const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: kPrimaryColor,
                                ),
                              ),
                            )
                            : Column(
                              children: [
                                _textFields(t, p),
                                const SizedBox(height: 24),
                                _actionButtons(t, p),
                                const SizedBox(height: 20),
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

  Widget _textFields(AppLocalizations t, SelfRegistrationProvider p) {
    return Column(
      children: [
        AppTextfield(
          hintText: t.translate('full_name'),
          controller: fullNameCtrl,
          prefixIcon: Icons.person_outline,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Please enter Full Name";
            if (!RegExp(r"^[a-zA-Z .]+$").hasMatch(v.trim())) {
              return "Only alphabets allowed";
            }
            if (v.trim().length < 3) return "Minimum 3 characters required";
            return null;
          },
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('mobile_number'),
          controller: mobileCtrl,
          keyboardType: TextInputType.number,
          maxlength: 10,
          prefixIcon: Icons.call,
          validator:
              (v) =>
                  RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : "Enter valid mobile number",
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('email'),
          controller: userEmailCtrl,
          prefixIcon: Icons.email_outlined,
          validator:
              (v) =>
                  RegExp(
                        r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                      ).hasMatch(v?.trim() ?? '')
                      ? null
                      : "Enter valid email",
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('pan_card'),
          controller: panCtrl,
          maxlength: 10,
          prefixIcon: Icons.credit_card,
          onChanged: (value) {
            final upper = value.toUpperCase();
            if (upper != value) {
              panCtrl.value = TextEditingValue(
                text: upper,
                selection: TextSelection.collapsed(offset: upper.length),
              );
            }
          },
          validator:
              (v) =>
                  RegExp(
                        r'^[A-Z]{5}[0-9]{4}[A-Z]$',
                      ).hasMatch((v ?? '').trim().toUpperCase())
                      ? null
                      : "Enter valid PAN Card Number",
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('hcf_name'),
          controller: hcfNameCtrl,
          prefixIcon: Icons.local_hospital_outlined,
          validator:
              (v) =>
                  v == null || v.trim().length < 3
                      ? "Enter valid HCF name"
                      : null,
        ),
        const SizedBox(height: 14),
        validatedApiDropdown(
          hint: t.translate('hcf_type'),
          value: p.selectedHcfType,
          items: p.hcfTypes,
          displayKey: "lookupDetDescEn",
          icon: Icons.local_hospital,
          errorText: "Please select HCF type",
          onChanged: p.selectHcfType,
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('hcf_contact_number'),
          controller: hcfContactCtrl,
          keyboardType: TextInputType.number,
          maxlength: 10,
          prefixIcon: Icons.call,
          validator:
              (v) =>
                  RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : "Enter valid contact",
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('hcf_email'),
          controller: hcfEmailCtrl,
          prefixIcon: Icons.email_outlined,
          validator:
              (v) =>
                  RegExp(
                        r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                      ).hasMatch(v?.trim() ?? '')
                      ? null
                      : "Enter valid email",
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('hcf_address'),
          controller: hcfAddressCtrl,
          prefixIcon: Icons.location_on_outlined,
          validator:
              (v) =>
                  v == null || v.trim().length < 5
                      ? "Enter valid address"
                      : null,
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('pincode'),
          controller: pincodeCtrl,
          maxlength: 6,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.numbers,
          validator:
              (v) =>
                  RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : "Enter valid pincode",
          onChanged: (v) {
            if (v.length == 6) p.loadLocation(v);
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: validatedApiDropdown(
                hint: t.translate('division'),
                value: p.selectedDivision,
                items: p.divisions,
                displayKey: "divName",
                icon: Icons.location_on,
                errorText: "Please select Division",
                onChanged: p.selectDivision,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: validatedApiDropdown(
                hint: t.translate('district'),
                value: p.selectedDistrict,
                items: p.districts,
                displayKey: "distName",
                icon: Icons.location_city,
                errorText: "Please select District",
                onChanged: p.selectDistrict,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        validatedApiDropdown(
          hint: t.translate('taluka'),
          value: p.selectedTaluka,
          items: p.talukas,
          displayKey: "talukaName",
          icon: Icons.map,
          errorText: "Please select Taluka",
          onChanged: p.selectTaluka,
        ),

        const SizedBox(height: 14),
        AppTextfield(
          hintText: '${t.translate('dr_registration_no')} *',
          controller: drRegNoCtrl,
          prefixIcon: Icons.badge_outlined,
          validator:
              (v) =>
                  v == null || v.trim().isEmpty
                      ? "Please enter Doc. Registration Number"
                      : null,
        ),
        const SizedBox(height: 16),
        _uploadSection(t, p),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('username'),
          controller: usernameCtrl,
          prefixIcon: Icons.account_circle_outlined,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Please enter Username";
            if (v.trim().length < 4) {
              return "Username must be at least 4 characters";
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('password'),
          controller: passwordCtrl,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          validator:
              (v) =>
                  passwordRegex.hasMatch(v?.trim() ?? '')
                      ? null
                      : t.translate('password_note'),
        ),
        const SizedBox(height: 14),
        AppTextfield(
          hintText: t.translate('confirm_password'),
          controller: confirmPassCtrl,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Please confirm password";
            if (v.trim() != passwordCtrl.text.trim()) {
              return "Passwords do not match";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            t.translate('password_note'),
            style: const TextStyle(fontSize: 10, color: kTextColor),
          ),
        ),
      ],
    );
  }

  Widget _uploadSection(AppLocalizations t, SelfRegistrationProvider p) {
    final doc = p.pickedDoc;
    if (doc == null) {
      return GestureDetector(
        onTap: p.submitting ? null : () => _pickDocument(t),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor, width: 2),
                ),
                child: const Icon(
                  Icons.upload_outlined,
                  size: 28,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.translate('reg_doc_upload_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${t.translate('max_file')}\n${t.translate('reg_doc_format')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: kPrimaryColor,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _humanSize(doc.size),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            splashRadius: 20,
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              color: kPrimaryColor,
            ),
            onPressed: _previewDocument,
          ),
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: p.submitting ? null : p.removeDocument,
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(AppLocalizations t, SelfRegistrationProvider p) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: t.translate('reset'),
            color: Colors.grey.shade400,
            padding: const EdgeInsets.all(10),
            onPressed: p.submitting ? () {} : _onReset,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text:
                p.submitting ? t.translate('please_wait') : t.translate('save'),
            color: Colors.deepOrange,
            padding: const EdgeInsets.all(10),
            onPressed: p.submitting ? () {} : () => _submit(t),
          ),
        ),
      ],
    );
  }
}
