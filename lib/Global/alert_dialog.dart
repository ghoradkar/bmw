import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 60, color: Colors.green),
          SizedBox(height: 16),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onConfirm,
            icon: Icon(Icons.arrow_forward),
            label: Text('Ok'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          )
        ],
      ),
    );
  }
}
