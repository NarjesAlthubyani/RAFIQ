import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuthInputField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final double height;
  final double radius;

  const AuthInputField({
    super.key,
    required this.hint,
    required this.obscure,
    this.height = 54,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background.withOpacity(0.92),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
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
