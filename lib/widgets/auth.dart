import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuthInputField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final double height;
  final double radius;
  final TextEditingController? controller; // ✅ ADD THIS LINE
  final TextInputType? keyboardType; // Optional: for email keyboard

  const AuthInputField({
    super.key,
    required this.hint,
    required this.obscure,
    this.height = 54,
    this.radius = 12,
    this.controller, // ✅ ADD THIS LINE
    this.keyboardType, // ✅ ADD THIS LINE
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller, // ✅ USE IT HERE
        obscureText: obscure,
        keyboardType: keyboardType, // ✅ USE IT HERE
        style: const TextStyle(color: Colors.black87), // Make text visible
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background.withOpacity(0.92),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class SocialSquare extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const SocialSquare({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}