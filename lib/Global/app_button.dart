import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color color;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    required this.color, // Orange color as per image
    this.icon = Icons.arrow_forward,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40), // Fully rounded edges
        ),
        padding: padding,
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
