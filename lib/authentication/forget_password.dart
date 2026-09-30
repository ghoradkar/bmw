import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Global/app_bar.dart';
import '../Global/app_button.dart';
import '../Global/app_textfield.dart';
import '../Global/size_config.dart';
import '../Global/url.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';
import '../network/network_aware.dart';
import '../network/network_status.dart';
import '../network/offline.dart';
import 'login_screen.dart';
// Make sure path is correct

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
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
      var userId = prefs.getString('UserId');


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
        "userId": userId,
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
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          // MaterialPageRoute(builder: (_) => const LoginScreen('yes')),
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
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    return StreamProvider<NetworkStatus>(
      create:
          (context) => NetworkStatusService().networkStatusController.stream,
      initialData: NetworkStatus.Online,
      child: NetworkAwareWidget(
        onlineChild: Scaffold(
          body: Stack(
            children: [
              // Background Image
              SizedBox.expand(
                child: Image.asset(
                  'assets/images/biowaste_background.png',
                  fit: BoxFit.cover,
                ),
              ),
              // White Card
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.topLeft,

                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_ios, color: kWhiteColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/applogo.jpeg',
                                    height: 80,
                                  ),
                                  Image.asset(
                                    'assets/images/logoo.png',
                                    height: 80,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'BMW Waste Management',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.translate('forgot_password'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Username
                              AppTextfield(
                                hintText: t.translate('username'),
                                controller: usernameController,
                                prefixIcon: Icons.person_outline,
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Enter username'
                                            : null,
                              ),
                              const SizedBox(height: 16),

                              // Old Password
                              AppTextfield(
                                hintText: t.translate('old_password'),
                                controller: oldPasswordController,
                                obscureText: true,
                                prefixIcon: Icons.password,
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Enter old password'
                                            : null,
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
                                  } else if (value !=
                                      newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  //  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 130,
                                    child: AppButton(
                                      text: t.translate('cancel'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },

                                      color: Colors.grey.shade400,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 18,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 130,
                                    child: AppButton(
                                      text: t.translate('reset'),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate() ==
                                            true) {
                                          resetPassword();
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Password Reset Failed.',
                                              ),
                                            ),
                                          );
                                        }

                                      },
                                      // isLoading: isLoading,
                                      color: Colors.deepOrange,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                        horizontal: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        offlineChild: Offline(),
      ),
    );}
}
