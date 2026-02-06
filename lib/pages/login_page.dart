import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double sidePadding = 26;
    final double contentWidth = size.width - (sidePadding * 2);
    final double fieldHeight = 54;
    final double fieldRadius = 12;
    final double baseTop = size.height * 0.45;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/riyadh.jpeg', fit: BoxFit.cover),

          // Light overlay
          Container(color: Colors.black.withOpacity(0.08)),

          SafeArea(
            child: Stack(
              children: [
                //Profile icon
                Positioned(
                  top: size.height * 0.22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/account.png',
                      width: 120,
                      height: 120,
                      color: Colors.white,
                    ),
                  ),
                ),

                //Email field
                Positioned(
                  top: baseTop,
                  left: sidePadding,
                  right: sidePadding,
                  child: SizedBox(
                    width: contentWidth,
                    child: _InputField(
                      height: fieldHeight,
                      radius: fieldRadius,
                      hint: 'Email',
                      obscure: false,
                    ),
                  ),
                ),

                //Password field
                Positioned(
                  top: baseTop + fieldHeight + 16,
                  left: sidePadding,
                  right: sidePadding,
                  child: SizedBox(
                    width: contentWidth,
                    child: _InputField(
                      height: fieldHeight,
                      radius: fieldRadius,
                      hint: 'Password',
                      obscure: true,
                    ),
                  ),
                ),

                // Forget password
                Positioned(
                  top: baseTop + (fieldHeight * 2) + 26,
                  left: sidePadding,
                  right: sidePadding,
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Forget your password? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(1.0),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Click me',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Login button
                Positioned(
                  top: baseTop + (fieldHeight * 2) + 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 190,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MainPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // OR line
                Positioned(
                  top: baseTop + (fieldHeight * 2) + 150,
                  left: sidePadding + 10,
                  right: sidePadding + 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.28),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.60),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.28),
                        ),
                      ),
                    ],
                  ),
                ),

                // Social buttons
                Positioned(
                  top: baseTop + (fieldHeight * 2) + 190,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialSquare(
                        onTap: () {},
                        child: Image.asset(
                          'assets/facebook_logo.png',
                          width: 45,
                          height: 45,
                        ),
                      ),
                      const SizedBox(width: 18),
                      _SocialSquare(
                        onTap: () {},
                        // Google logo
                        child: Image.asset(
                          'assets/google_logo.png',
                          width: 26,
                          height: 26,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom text
                Positioned(
                  bottom: 34,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't Have An Account? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(1.0),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}

class _InputField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final double height;
  final double radius;

  const _InputField({
    required this.hint,
    required this.obscure,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background.withOpacity(0.92),
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SocialSquare extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _SocialSquare({required this.onTap, required this.child});

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
