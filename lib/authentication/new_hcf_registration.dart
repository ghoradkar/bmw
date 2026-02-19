import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:mpcb_bio_waste/Global/url.dart';
import 'package:mpcb_bio_waste/Localization/app_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_dialog.dart';
import '../Global/app_dropdown.dart';
import '../Global/app_textfield.dart';
import '../Global/size_config.dart';
import '../localization/provider.dart';

class NewHCFRegisterScreen extends StatefulWidget {
  const NewHCFRegisterScreen({Key? key}) : super(key: key);

  @override
  State<NewHCFRegisterScreen> createState() => _NewHCFRegisterScreenState();
}

class _NewHCFRegisterScreenState extends State<NewHCFRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final hcfNameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  bool _isLoading = false;

  List<Map<String, dynamic>> hcfTypeList = [];
  Map<String, dynamic>? selectedHcfType;

  List<Map<String, dynamic>> locationList = [];

  Map<String, dynamic>? selectedDivision;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedTaluka;
  Map<String, dynamic>? selectedSro;
  Map<String, dynamic>? selectedRo;
  List<Map<String, dynamic>> divisionList = [];
  List<Map<String, dynamic>> districtList = [];
  List<Map<String, dynamic>> talukaList = [];
  List<Map<String, dynamic>> sroList = [];
  List<Map<String, dynamic>> roList = [];


  @override
  void initState() {
    super.initState();
    fetchHCFType();
  }

  /* ---------------- HCF TYPE API ---------------- */

  Future<void> fetchHCFType() async {
    setState(() => _isLoading = true);

    try {
      final response =
      await http.get(Uri.parse('$masterurl$HCF_TYPE'));

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        hcfTypeList = List<Map<String, dynamic>>.from(res['data'] ?? []);
      }
    } catch (_) {
      _showError("Failed to fetch HCF type");
    }

    setState(() => _isLoading = false);
  }

  /* ---------------- PINCODE API ---------------- */

  Future<void> fetchPincodeData() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$masterurl$GET_DATA_BY_PINCODE${pincodeCtrl.text.trim()}'),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final List data = res['data'] ?? [];

        /// 🔹 Raw list
        locationList = List<Map<String, dynamic>>.from(data);

        /// 🔹 Deduplicate helpers
        Map<int, Map<String, dynamic>> divMap = {};
        Map<int, Map<String, dynamic>> distMap = {};
        Map<int, Map<String, dynamic>> talukaMap = {};
        Map<int, Map<String, dynamic>> sroMap = {};
        Map<int, Map<String, dynamic>> roMap = {};

        for (var item in locationList) {
          divMap[item['divId']] = item;
          distMap[item['distId']] = item;
          talukaMap[item['talukaId']] = item;
          sroMap[item['lookupSroId']] = item;
          roMap[item['lookupRoId']] = item;
        }

        /// 🔹 Final unique lists
        divisionList = divMap.values.toList();
        districtList = distMap.values.toList();
        talukaList = talukaMap.values.toList();
        sroList = sroMap.values.toList();
        roList = roMap.values.toList();

        /// 🔹 Auto-select first item (if exists)
        selectedDivision = divisionList.isNotEmpty ? divisionList.first : null;
        selectedDistrict = districtList.isNotEmpty ? districtList.first : null;
        selectedTaluka = talukaList.isNotEmpty ? talukaList.first : null;
        selectedSro = sroList.isNotEmpty ? sroList.first : null;
        selectedRo = roList.isNotEmpty ? roList.first : null;
      }
    } catch (e) {
      _showError("Failed to fetch address");
    }

    setState(() => _isLoading = false);
  }


  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  /* ---------------- save hcf ---------------- */
  Future<void> saveHcf(t) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix validation errors")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
    //  final token = prefs.getString('Token') ?? '';

      /// 🔹 REQUEST BODY (exact mapping)
      final Map<String, dynamic> body = {
        "lookupDetHierIdDivision":
        selectedDivision?['divId']?.toString(),
        "lookupDetHierIdDistrict":
        selectedDistrict?['distId']?.toString(),
        "lookupDetHierIdTaluka":
        selectedTaluka?['talukaId']?.toString(),
        "pincode": pincodeCtrl.text.trim(),
        "lookupDetIdTypeOfHcf":
        selectedHcfType?['lookupDetId']?.toString(),
        "nameOfHcf": hcfNameCtrl.text.trim(),
        "address1": addressCtrl.text.trim(),
        "hcfOwnerContact": contactCtrl.text.trim(),
        "emailId": emailCtrl.text.trim(),
      };

      debugPrint("SAVE HCF BODY → $body");

      final response = await http.post(
        Uri.parse('$masterurl$NEW_HCF_REGISTRATION'), // 🔴 replace with actual API
        headers: {
          "Content-Type": "application/json",
         // "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 && res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("HCF saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialog(buttonText: t.translate('ok'),
            message: t.translate('new_hcf_save'),
            onOk: () {
             launchUrl(Uri.parse('https://www.ecmpcb.in/registration'));
            },
          ),
        );


        /// Optional: reset form
        _formKey.currentState?.reset();
        setState(() {
          hcfNameCtrl.clear();
          emailCtrl.clear();
          contactCtrl.clear();
          addressCtrl.clear();
          pincodeCtrl.clear();
          selectedHcfType =
              selectedDivision =
              selectedDistrict =
              selectedTaluka =
              selectedSro =
              selectedRo = null;
        });
      } else {
        throw res['message'] ?? "Save failed";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save HCF"),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("SAVE HCF ERROR → $e");
    }

    setState(() => _isLoading = false);
  }


  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      body: Stack(
        children: [
          mAppBar(
            scTitle: t.translate('new_hcf') ,
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
                 //   autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: _isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: kPrimaryColor,
                      ),
                    )
                        : Column(
                      children: [
                        _textFields(t),
                        const SizedBox(height: 30),
                        _actionButtons(t),
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

  /* ---------------- FIELDS ---------------- */

  Widget _textFields(t) {
    return Column(
      children: [
        AppTextfield(
          hintText:  t.translate('hcf_name'),
          controller: hcfNameCtrl,
          prefixIcon: Icons.local_hospital_outlined,
          validator: (v) =>
          v == null || v.trim().length < 3 ? "Enter valid HCF name" : null,
        ),

        const SizedBox(height: 14),

        validatedApiDropdown(
          hint:  t.translate('hcf_type'),
          value: selectedHcfType,
          items: hcfTypeList,
          displayKey: "lookupDetDescEn",
          icon: Icons.local_hospital,
          errorText: "Please select HCF type",
          onChanged: (v) => setState(() => selectedHcfType = v),
        ),

        const SizedBox(height: 14),

        AppTextfield(
          hintText:  t.translate('hcf_contact_number'),
          controller: contactCtrl,
          keyboardType: TextInputType.phone,
          maxlength: 10,
          prefixIcon: Icons.call,
          validator: (v) =>
          RegExp(r'^[0-9]{10}$').hasMatch(v ?? "")
              ? null
              : "Enter valid contact",
        ),

        const SizedBox(height: 14),

        AppTextfield(
          hintText:  t.translate('hcf_email'),
          controller: emailCtrl,
          prefixIcon: Icons.email_outlined,
          validator: (v) =>
          RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(v ?? "")
              ? null
              : "Enter valid email",
        ),

        const SizedBox(height: 14),

        AppTextfield(
          hintText:  t.translate('hcf_address'),
          controller: addressCtrl,
          prefixIcon: Icons.location_on_outlined,
          validator: (v) =>
          v == null || v.length < 5 ? "Enter valid address" : null,
        ),

        const SizedBox(height: 14),

        AppTextfield(
          hintText:  t.translate('pincode'),
          controller: pincodeCtrl,
          maxlength: 6,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.numbers,
          validator: (v) =>
          v != null && v.length == 6 ? null : "Enter valid pincode",
          onChanged: (v) {
            if (v.length == 6) fetchPincodeData();
          },
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: validatedApiDropdown(
                hint:  t.translate('division'),
                value: selectedDivision,
                items: divisionList,
                displayKey: "divName",
                icon: Icons.location_on,
                errorText: "Please select Division",
                onChanged: (val) => setState(() => selectedDivision = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: validatedApiDropdown(
    hint:  t.translate('district'),
    value: selectedDistrict,
    items: districtList,
    displayKey: "distName",
    icon: Icons.location_city,
    errorText: "Please select District",
    onChanged: (val) => setState(() => selectedDistrict = val),
    ),)
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child:validatedApiDropdown(
                hint:  t.translate('taluka'),
                value: selectedTaluka,
                items: talukaList,
                displayKey: "talukaName",
                icon: Icons.map,
                errorText: "Please select Taluka",
                onChanged: (val) => setState(() => selectedTaluka = val),
              ),

            ),
            const SizedBox(width: 12),
            Expanded(
              child: validatedApiDropdown(
                hint: "SRO",
                value: selectedSro,
                items: sroList,
                displayKey: "sroName",
                icon: Icons.account_tree_outlined,
                errorText: "Select SRO",
                onChanged: (v) => setState(() => selectedSro = v),
              ),


            ),
          ],
        ),

        const SizedBox(height: 14),

        validatedApiDropdown(
          hint: "RO",
          value: selectedRo,
          items: roList,
          displayKey: "roName",
          icon: Icons.account_balance,
          errorText: "Select RO",
          onChanged: (v) => setState(() => selectedRo = v),
        ),

      ],
    );
  }

  Widget _actionButtons(t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        SizedBox(
          width: 130,
          child: AppButton(
            text:  t.translate('reset'),
            color: Colors.grey.shade400,
            onPressed: () { _formKey.currentState?.reset();
            hcfNameCtrl.clear();
            emailCtrl.clear();
            contactCtrl.clear();
            addressCtrl.clear();
            pincodeCtrl.clear();}, padding: EdgeInsets.all(10),
          ),
        ),
        SizedBox(
          width: 130,
          child: AppButton(
            text:  t.translate('save'),
            color: Colors.deepOrange,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                debugPrint("Form valid ✅");
                saveHcf(t);

              }
            }, padding: EdgeInsets.all(10),
          ),
        ),
      ],
    );
  }
}
