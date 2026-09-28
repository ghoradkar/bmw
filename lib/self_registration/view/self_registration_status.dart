import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/authentication/logout.dart';
import 'package:provider/provider.dart';

import '../../../Global/app_bar.dart';
import '../../../Global/app_button.dart';
import '../../../Global/constant.dart';
import '../../../Global/size_config.dart';
import '../../../Localization/app_localization.dart';
import '../../../localization/provider.dart';

/// Shown after a self-registered ("temp survey HCF") user signs in while their
/// registration is still under scrutiny. It is intentionally a plain
/// informational screen: once an officer approves the registration and assigns
/// a real role, the normal role-based routing takes over on the next login.
class SelfRegistrationStatusScreen extends StatelessWidget {
  const SelfRegistrationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final t = AppLocalizations.of(context);
    context.watch<LanguageProvider>();

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Scaffold(
        backgroundColor: kWhiteColor,
        body: Stack(
          children: [
            mAppBar(
              scTitle: t.translate('registration_status'),
              centerTile: true,
              showLeading: false,
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
                  child: LayoutBuilder(
                    builder:
                        (context, constraints) => SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 72,
                                    color: kPrimaryDarkColor,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    t.translate('registration_pending_title'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t.translate('registration_pending_msg'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextColor,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  SizedBox(
                                    width: 170,
                                    child: AppButton(
                                      text: t.translate('logout'),
                                      color: Colors.deepOrange,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 16,
                                      ),
                                      onPressed:
                                          () => AuthService().logout(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
