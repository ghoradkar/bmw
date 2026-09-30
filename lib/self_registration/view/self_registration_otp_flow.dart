import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mpcb_bio_waste/Global/app_dialog.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:mpcb_bio_waste/Localization/app_localization.dart';
import 'package:mpcb_bio_waste/localization/provider.dart';
import 'package:mpcb_bio_waste/self_registration/model/self_registration_models.dart';
import 'package:mpcb_bio_waste/self_registration/provider/self_registration_provider.dart';
import 'package:mpcb_bio_waste/self_registration/view/self_registration.dart';

/// Caps the system text scale for a dialog so an extreme "maximum font size"
/// device setting can't grow the content past the screen and push the action
/// button out of reach. Presentational only — no behaviour change.
Widget _capFontScale(Widget child) =>
    MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child);

/// Self Registration entry flow:
///
///   mobile dialog  ->  OTP dialog (verifies + searches by mobile)  ->
///     found / not-found  ->  "OTP Verified" dialog  ->  form screen (pre-filled)
///     already submitted  ->  info dialog, stop
///     lookup error       ->  info dialog, stop (retry — never a blank form)
///
/// Send-OTP calls `search-registration/by-otp`; the user-by-mobile search then
/// carries the entered `otp` and both verifies it and returns the registration
/// data in one call (`SelfRegistrationProvider.searchByMobile`).
Future<void> openSelfRegistrationFlow(BuildContext context) async {
  final t = AppLocalizations.of(context);

  final mobile = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _capFontScale(const _MobileDialog()),
  );
  if (mobile == null || mobile.isEmpty || !context.mounted) return;

  final search = await showDialog<SelfRegistrationSearchResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _capFontScale(_OtpDialog(mobile: mobile)),
  );
  if (search == null || !context.mounted) return;

  // Already-submitted applicants can't register again — show the reason, stop.
  if (search.status == SelfRegistrationSearchStatus.alreadySubmitted) {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => _capFontScale(
            _InfoDialog(
              message:
                  search.message.isNotEmpty
                      ? search.message
                      : t.translate('registration_pending_msg'),
              buttonText: t.translate('ok'),
            ),
          ),
    );
    return;
  }

  // Lookup couldn't be completed (server down / bad response) — don't open a
  // blank form (risks a duplicate the user thinks is their first). Stop, retry.
  if (search.status == SelfRegistrationSearchStatus.error) {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => _capFontScale(
            _InfoDialog(
              message:
                  search.message.isNotEmpty
                      ? search.message
                      : t.translate('self_reg_lookup_failed'),
              buttonText: t.translate('ok'),
            ),
          ),
    );
    return;
  }

  // Found -> carry the data into the form; not-found -> blank form.
  final prefill = search.isFound ? search.data : null;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => _capFontScale(
          SuccessDialog(
            message: t.translate('otp_verified'),
            buttonText: t.translate('ok'),
            onOk: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => SelfRegistration(
                        verifiedMobile: mobile,
                        prefill: prefill,
                      ),
                ),
              );
            },
          ),
        ),
  );
}

/* ----------------------------------------------------------------------------
 * DIALOG 1 — enter the registered mobile number
 * ------------------------------------------------------------------------- */

class _MobileDialog extends StatefulWidget {
  const _MobileDialog();

  @override
  State<_MobileDialog> createState() => _MobileDialogState();
}

class _MobileDialogState extends State<_MobileDialog> {
  final _controller = TextEditingController();
  static final _mobileRegex = RegExp(r'^[6-9]\d{9}$');

  bool _sending = false;
  String? _error;

  bool get _valid => _mobileRegex.hasMatch(_controller.text.trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sends the OTP (`search-registration/by-otp`) and only advances to the OTP
  /// dialog on success.
  Future<void> _sendOtp() async {
    if (!_valid || _sending) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });

    final result = await SelfRegistrationProvider.sendOtp(
      _controller.text.trim(),
    );
    if (!mounted) return;

    if (result.isSent) {
      Navigator.of(context).pop(_controller.text.trim());
      return;
    }
    setState(() {
      _sending = false;
      _error =
          result.message.trim().isNotEmpty
              ? result.message
              : t.translate('otp_send_failed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    context.watch<LanguageProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.translate('self_registration'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t.translate('self_reg_mobile_subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: kBlackColor),
                ),
                const SizedBox(height: 26),
                _MobileNumberField(
                  controller: _controller,
                  onChanged:
                      (_) => setState(() {
                        if (_error != null) _error = null;
                      }),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 34),
                _PillButton(
                  text: t.translate('send_otp'),
                  enabled: _valid && !_sending,
                  loading: _sending,
                  onTap: _sendOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors the login screen's OTP mobile field (gradient icon + `+91 ` prefix).
class _MobileNumberField extends StatelessWidget {
  const _MobileNumberField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      cursorColor: kBlackColor,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: Colors.black87, fontSize: 12),
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        labelText: t.translate('mobile_no'),
        hintText: t.translate('enter_mobile_no'),
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
      ),
    );
  }
}

/* ----------------------------------------------------------------------------
 * DIALOG 2 — enter the 6-digit OTP
 * ------------------------------------------------------------------------- */

class _OtpDialog extends StatefulWidget {
  const _OtpDialog({required this.mobile});

  final String mobile;

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  Timer? _timer;
  int _seconds = _resendSeconds;

  bool _verifying = false;
  bool _resending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _nodes = List.generate(_otpLength, (_) => FocusNode());
    for (final n in _nodes) {
      n.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = _resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_seconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _complete => _code.length == _otpLength;

  String get _maskedMobile {
    final m = widget.mobile;
    if (m.length <= 4) return m;
    return '${'*' * (m.length - 4)}${m.substring(m.length - 4)}';
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
      }
    } else if (index > 0) {
      _nodes[index - 1].requestFocus();
    }
    if (_errorText != null) _errorText = null;
    setState(() {});
  }

  Future<void> _resend() async {
    if (_seconds != 0 || _resending) return;
    final t = AppLocalizations.of(context);
    setState(() => _resending = true);

    final result = await SelfRegistrationProvider.sendOtp(widget.mobile);
    if (!mounted) return;

    if (result.isSent) {
      for (final c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      _errorText = null;
      _startTimer();
      setState(() => _resending = false);
    } else {
      setState(() {
        _resending = false;
        _errorText =
            result.message.trim().isNotEmpty
                ? result.message
                : t.translate('otp_send_failed');
      });
    }
  }

  Future<void> _verify() async {
    if (!_complete || _verifying) return;
    FocusScope.of(context).unfocus();
    final t = AppLocalizations.of(context);
    setState(() {
      _verifying = true;
      _errorText = null;
    });

    // The search call verifies the OTP and returns the registration data in a
    // single step — there is no separate verify-OTP endpoint here.
    final result = await SelfRegistrationProvider.searchByMobile(
      widget.mobile,
      _code,
    );

    if (!mounted) return;

    // Wrong / expired OTP: keep this dialog open so the user can retry or
    // resend, instead of being dropped out of the flow. Heuristic on the server
    // message — the exact wrong-OTP response shape isn't in the API doc yet, so
    // anything else still falls through to the caller's handling.
    if (result.status == SelfRegistrationSearchStatus.error &&
        result.message.toLowerCase().contains('otp')) {
      setState(() {
        _verifying = false;
        _errorText =
            result.message.toLowerCase().contains('expire')
                ? t.translate('otp_expired')
                : t.translate('otp_wrong');
      });
      return;
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    context.watch<LanguageProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.translate('enter_otp'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.translate('otp_sent_to', params: {'mobile': _maskedMobile}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kTextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: List.generate(
                    _otpLength,
                    (i) => Expanded(child: _otpBox(i)),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  '${(_seconds ~/ 60).toString().padLeft(2, '0')} : '
                  '${(_seconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      t.translate('didnt_receive_otp'),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: (_seconds == 0 && !_resending) ? _resend : null,
                      child:
                          _resending
                              ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                t.translate('resend'),
                                style: TextStyle(
                                  color:
                                      _seconds == 0
                                          ? Colors.black
                                          : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _PillButton(
                  text: t.translate('verify'),
                  enabled: _complete && !_verifying,
                  loading: _verifying,
                  onTap: _verify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int i) {
    final bool focused = _nodes[i].hasFocus;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          border: Border.all(
            color: focused ? kPrimaryDarkColor : Colors.grey.shade400,
            width: focused ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: _controllers[i],
          focusNode: _nodes[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _onChanged(i, v),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------------------------
 * Shared pill button — grey while disabled, deep-orange with arrow when enabled
 * ------------------------------------------------------------------------- */

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.text,
    required this.enabled,
    required this.onTap,
    this.loading = false,
  });

  final String text;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && !loading;
    final Color bg =
        (active || loading) ? Colors.deepOrange : const Color(0xFFEDEDED);
    final Color fg =
        (active || loading) ? Colors.white : const Color(0xFF9E9E9E);

    return SizedBox(
      width: 190,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: active ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
            child:
                loading
                    ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            text,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward, color: fg, size: 20),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------------------------
 * Blocking info dialog (e.g. "application already under scrutiny")
 * ------------------------------------------------------------------------- */

class _InfoDialog extends StatelessWidget {
  const _InfoDialog({required this.message, required this.buttonText});

  final String message;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: kPrimaryDarkColor,
                  size: 44,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 22),
                _PillButton(
                  text: buttonText,
                  enabled: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
