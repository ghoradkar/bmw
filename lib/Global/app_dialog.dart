import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';
import 'package:mpcb_bio_waste/Global/images.dart';
import 'package:url_launcher/url_launcher.dart';

class SuccessDialog extends StatelessWidget {
  final String message;
  final String buttonText;
  final String? redirectUrl;
  final VoidCallback? onOk;

  const SuccessDialog({
    Key? key,
    required this.message,
    required this.buttonText ,
    this.redirectUrl,
    this.onOk,
  }) : super(key: key);

  Future<void> _handleOk(BuildContext context) async {
    Navigator.of(context).pop();

    if (onOk != null) {
      onOk!();
      return;
    }

    if (redirectUrl != null) {
      final uri = Uri.parse(redirectUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ✅ Green Tick
            Image.asset(success),

            const SizedBox(height: 20),

            /// Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            /// OK Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 15),
                ),
                onPressed: () => _handleOk(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(buttonText,style: TextStyle(color: kWhiteColor),),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward,color: kWhiteColor,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
