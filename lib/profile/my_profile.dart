import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/Global/app_textfield.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/size_config.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  Map<String,dynamic>user={};

  // Controllers for all fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController orgNameController = TextEditingController();
  final TextEditingController projectController = TextEditingController();
  final TextEditingController supervisorController = TextEditingController();
  final TextEditingController supervisorMobileController = TextEditingController();
  final TextEditingController hcfCodeController = TextEditingController();
  final TextEditingController vendorNameController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  Future<void> _loadUserInfo() async {
    setState(() => isLoading = true);

    String checkValue(dynamic val) {
      if (val == null || val.toString().trim().isEmpty) {
        return '-';
      }
      return val.toString();
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        final user = jsonDecode(userString);

        // Fill controllers with SharedPreferences data
        usernameController.text = checkValue(user['userName']);
        fullNameController.text = checkValue(user['userFullName']);
        emailController.text = checkValue(user['emailId']);
        mobileController.text = checkValue(user['mobileNumber']);
        orgNameController.text = checkValue(user['orgName']);
        projectController.text = checkValue(user['projName']);
        supervisorController.text = checkValue(user['supervisorName']);
        supervisorMobileController.text = checkValue(user['supervisorMobNo']);
        hcfCodeController.text = checkValue(user['hcfCode']);
        vendorNameController.text = checkValue(user['vendorName']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }

    setState(() => isLoading = false);
  }






  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
        body: Stack(
        children: [
        mAppBar(
        scTitle: t.translate('my_profile'),
        centerTile: false,
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
    child: isLoading
    ? const Center(
    child: CircularProgressIndicator(
    color: kPrimaryColor,
    ),
    )
        : Column(
            children: [
              // Profile Image
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kWhiteColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15), // subtle shadow
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4), // horizontal & vertical offset
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.black54),
              ),


              // All fields (read-only)
              AppTextfield(
                readOnly: true,

                controller: usernameController,
                hintText: t.translate('username'),
                prefixIcon: Icons.person,
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: fullNameController,
                hintText: t.translate('full_name'),
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: emailController,
                hintText: t.translate('email'),
                prefixIcon: Icons.email,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: mobileController,
                hintText: t.translate('mobile_number'),
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: orgNameController,
                hintText: t.translate('org_name'),
                prefixIcon: Icons.apartment,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: projectController,
                hintText: t.translate('project'),
                prefixIcon: Icons.work,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: supervisorController,
                hintText: t.translate('supervisor'),
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: supervisorMobileController,
                hintText: t.translate('supervisor_mobile'),
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: hcfCodeController,
                hintText: t.translate('hcf_code'),
                prefixIcon: Icons.tag,
              ),
              const SizedBox(height: 12),
              AppTextfield(
                readOnly: true,
                controller: vendorNameController,
                hintText: t.translate('vendor_name'),
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ))]));
  }
}
