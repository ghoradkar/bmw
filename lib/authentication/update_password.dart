import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_dropdown.dart';
import '../Global/app_textfield.dart';
import '../Global/constant.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';
import 'login_screen.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({Key? key}) : super(key: key);

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  Future<void> resetPassword() async {
    try {
      final uri = Uri.parse('$masterurl$RESET_PASSWORD');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('Token') ?? '';

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
        "Authorization": "Bearer $token",
      };

      final body = {
        "userName": usernameController.text.trim(),
        "oldPassword": oldPasswordController.text.trim(),
        "newPassword": newPasswordController.text.trim(),
        "confirmPassword": confirmPasswordController.text.trim(),
        // "userId": userId,
        "password": newPasswordController.text.trim(),
        "floginPwreset": "N",
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      final Map<String, dynamic> result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful. Please login again.'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen('yes')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Password reset failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      var username = prefs.getString('username') ?? 'Guest';
      usernameController.text=username;
      setState(() {

      });

    });
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
            scTitle: t.translate('update_password'),
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
                  padding: const EdgeInsets.all(25),
                  child: Form(key: _formKey, child: Column(children: [
                    // Username
                    AppTextfield(
                      hintText: t.translate('username'),
                      controller: usernameController,
                      prefixIcon: Icons.person_outline,
                      readOnly: true,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter username' : null,
                    ),
                    const SizedBox(height: 16),

                    // Old Password
                    AppTextfield(
                      hintText: t.translate('old_password'),
                      controller: oldPasswordController,
                      obscureText: true,
                      prefixIcon: Icons.password,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter old password' : null,
                    ),
                    const SizedBox(height: 16),

                    // New Password
                    AppTextfield(
                      hintText: t.translate('new_password'),
                      controller: newPasswordController,
                      obscureText: true,
                      prefixIcon: Icons.password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter new password';
                        } else if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    AppTextfield(
                      hintText: t.translate('confirm_password'),
                      controller: confirmPasswordController,
                      obscureText: true,
                      prefixIcon: Icons.password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm new password';
                        } else if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        //  const SizedBox(width: 16),

                        SizedBox(
                            width: 130,
                            child:AppButton(
                              text: t.translate('cancel'),
                              onPressed: () {
                                Navigator.pop(context);
                              },

                              color: Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 18),
                            )), SizedBox(
                            width: 170,
                            child:AppButton(
                              text: t.translate('update_password'),
                              onPressed: () {
                                if(_formKey.currentState!.validate()==true){
                                  resetPassword();
                                }
                                else{
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password Reset Failed.'),
                                    ),
                                  );
                                };

                              },
                              // isLoading: isLoading,
                              color: Colors.deepOrange,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 18),
                            )),
                      ],
                    ),
                    SizedBox(height: 30,),
                  ])),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
