import 'package:flutter/material.dart';
import 'package:mpcb_bio_waste/Global/constant.dart';

class AppTextfield extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxlength;
  final ValueChanged<String>? onChanged;
  final bool? readOnly;

  const AppTextfield({
    Key? key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxlength,
    this.onChanged,
    this.readOnly,

  }) : super(key: key);

  @override
  State<AppTextfield> createState() => _AppTextfieldState();
}

class _AppTextfieldState extends State<AppTextfield> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,

      controller: widget.controller,
      obscureText: _isObscured,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      cursorColor: kBlackColor,
      maxLength: widget.maxlength,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly??false,
      style: const TextStyle(color: Colors.black87,fontSize: 12),

      decoration: InputDecoration(
        labelText: widget.hintText,
        hintText: widget.hintText,
        labelStyle: TextStyle(fontSize: 13),
        hintStyle: TextStyle(fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.auto,

        filled: true,
        fillColor: widget.readOnly==true?Colors.grey.shade200:kWhiteColor,

        prefixIcon: widget.prefixIcon != null
            ? ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Icon(widget.prefixIcon, color: Colors.white),
        )
            : null,

        /// 👁️ Suffix icon ONLY for password field
        suffixIcon: widget.obscureText
            ? IconButton(
          splashRadius: 20,
          icon: Icon(
            _isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color:_isObscured? Colors.grey:Colors.lightBlue,
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        )
            : null,

        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:mpcb_bio_waste/Global/constant.dart';
//
// class AppTextfield extends StatefulWidget {
//   final String hintText;
//   final TextEditingController controller;
//   final bool obscureText;
//   final IconData? prefixIcon;
//   final String? Function(String?)? validator;
//   final TextInputType keyboardType;
//
//   const AppTextfield({
//     Key? key,
//     required this.hintText,
//     required this.controller,
//     this.obscureText = false,
//     this.prefixIcon,
//     this.validator,
//     this.keyboardType = TextInputType.text,
//   }) : super(key: key);
//
//   @override
//   State<AppTextfield> createState() => _AppTextfieldState();
// }
//
// class _AppTextfieldState extends State<AppTextfield> {
//   late bool _isObscured;
//
//   @override
//   void initState() {
//     super.initState();
//     _isObscured = widget.obscureText;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: widget.controller,
//       obscureText: _isObscured,
//       validator: widget.validator,
//       keyboardType: widget.keyboardType,
//       cursorColor: kBlackColor,
//       style: const TextStyle(color: Colors.black87),
//
//       decoration: InputDecoration(
//         labelText: widget.hintText, // 👈 floating label
//         hintText: widget.hintText,
//         floatingLabelBehavior: FloatingLabelBehavior.auto,
//         filled: true,
//         fillColor: kWhiteColor,
//
//         labelStyle: const TextStyle(color: Colors.grey),
//         hintStyle: const TextStyle(color: Colors.grey),
//
//         prefixIcon: widget.prefixIcon != null
//             ? ShaderMask(
//           shaderCallback: (bounds) => const LinearGradient(
//             colors: [Color(0xFF00BCD4), Color(0xFF2196F3)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ).createShader(bounds),
//           child: Icon(
//             widget.prefixIcon,
//             color: Colors.white,
//           ),
//         )
//             : null,
//
//         // 👁️ Eye icon logic
//         suffixIcon: widget.obscureText
//             ? IconButton(
//           icon: Icon(
//             _isObscured
//                 ? Icons.visibility_off_outlined
//                 : Icons.visibility_outlined,
//             color: Colors.grey,
//           ),
//           onPressed: () {
//             setState(() {
//               _isObscured = !_isObscured;
//             });
//           },
//         )
//             : null,
//
//         contentPadding:
//         const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Colors.grey),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Colors.grey),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: kPrimaryDarkColor),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Colors.red),
//         ),
//       ),
//     );
//   }
// }
