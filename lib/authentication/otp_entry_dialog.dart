import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../Global/app_button.dart';
import '../Global/constant.dart';
import '../Global/url.dart';
import '../Localization/app_localization.dart';
import '../localization/provider.dart';

/// "Enter OTP" modal for the **Sign in with OTP** flow.
///
/// On **Verify** it calls `verify-mobile-otp`. On success it pops with the auth
/// response map (top-level `jwtToken` + `tmUsers` object) so the caller can run
/// the shared post-login handling. On "Wrong OTP" / "OTP Expired" it stays open
/// and shows an inline error. **Resend** re-triggers `login-by-mobile`.
class OtpEntryDialog extends StatefulWidget {
  final String mobile;

  /// Device OS string (same value the password login sends as `osVersion`).
  final String osVersion;

  const OtpEntryDialog({
    super.key,
    required this.mobile,
    required this.osVersion,
  });

  @override
  State<OtpEntryDialog> createState() => _OtpEntryDialogState();
}

class _OtpEntryDialogState extends State<OtpEntryDialog> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 60;

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

  /// Maps a known server `message` to a localized string; falls back to the raw
  /// message, then to a generic key.
  String _localizedMessage(
    AppLocalizations t,
    String serverMessage,
    String fallbackKey,
  ) {
    final m = serverMessage.toLowerCase();
    if (m.contains('wrong otp')) return t.translate('otp_wrong');
    if (m.contains('otp expired')) return t.translate('otp_expired');
    if (m.contains('user not found')) {
      return t.translate('mobile_not_registered');
    }
    if (serverMessage.trim().isNotEmpty) return serverMessage;
    return t.translate(fallbackKey);
  }

  Future<void> _resend() async {
    if (_seconds != 0 || _resending) return;
    final t = AppLocalizations.of(context);
    setState(() => _resending = true);
    try {
      final response = await http.post(
        Uri.parse('$login_baseurl$LOGIN_BY_MOBILE'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNo': widget.mobile}),
      );
      debugPrint('RESEND OTP ${response.statusCode} -> ${response.body}');

      String msg = '';
      try {
        msg = (jsonDecode(response.body)['message'] ?? '').toString();
      } catch (_) {}

      if (!mounted) return;
      if (response.statusCode == 200 && msg.toLowerCase() == 'success') {
        for (final c in _controllers) {
          c.clear();
        }
        _nodes.first.requestFocus();
        _errorText = null;
        _startTimer();
        setState(() {});
      } else {
        setState(() =>
            _errorText = _localizedMessage(t, msg, 'otp_send_failed'));
      }
    } catch (e) {
      debugPrint('RESEND OTP ERROR -> $e');
      if (mounted) {
        setState(() => _errorText = t.translate('otp_send_failed'));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify(AppLocalizations t) async {
    if (_verifying) return;
    if (_code.length != _otpLength) {
      setState(() => _errorText = t.translate('enter_6_digit_otp'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _errorText = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$login_baseurl$VERIFY_MOBILE_OTP'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNo': widget.mobile,
          'otp': _code,
          'currLoginOutFlag': 'L',
          'appversion': appVersion,
          'osVersion': widget.osVersion,
          'appName': 'Survey',
        }),
      );
      debugPrint(
          'VERIFY-MOBILE-OTP ${response.statusCode} -> ${response.body}');

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        if (mounted) {
          setState(() => _errorText = t.translate('otp_verify_failed'));
        }
        return;
      }

      if (response.statusCode == 200 && body.containsKey('jwtToken')) {
        if (!mounted) return;
        Navigator.of(context).pop(body);
        return;
      }

      final msg = (body['message'] ?? '').toString();
      if (!mounted) return;
      setState(() =>
          _errorText = _localizedMessage(t, msg, 'otp_verify_failed'));
    } catch (e) {
      debugPrint('VERIFY-MOBILE-OTP ERROR -> $e');
      if (mounted) {
        setState(() => _errorText = t.translate('otp_verify_failed'));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    context.watch<LanguageProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.translate('enter_otp'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.translate('didnt_receive_otp'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: (_seconds == 0 && !_resending) ? _resend : null,
                  child: _resending
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          t.translate('resend'),
                          style: TextStyle(
                            color: _seconds == 0 ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _verifying
                ? const SizedBox(
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : SizedBox(
                    width: 170,
                    child: AppButton(
                      text: t.translate('verify'),
                      color: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 18,
                      ),
                      onPressed: () => _verify(t),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int i) {
    final bool focused = _nodes[i].hasFocus;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          border: Border.all(
            color: focused ? kPrimaryDarkColor : Colors.grey.shade400,
            width: focused ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
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
