import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/auth.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const sidePadding = 26.0;
    final baseTop = size.height * 0.45;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/riyadh.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.08)),

          SafeArea(
            child: Stack(
              children: [
                // Profile icon
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

                // Email field
                Positioned(
                  top: baseTop,
                  left: sidePadding,
                  right: sidePadding,
                  child: const AuthInputField(hint: 'Email', obscure: false),
                ),

                // Name field
                Positioned(
                  top: baseTop + 70,
                  left: sidePadding,
                  right: sidePadding,
                  child: const AuthInputField(hint: 'Name', obscure: false),
                ),

                // Password field
                Positioned(
                  top: baseTop + 140,
                  left: sidePadding,
                  right: sidePadding,
                  child: const AuthInputField(hint: 'Password', obscure: true),
                ),

                // Sign up button
                Positioned(
                  top: baseTop + 210,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 190,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/main');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // OR line
                Positioned(
                  top: baseTop + 270,
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
                  top: baseTop + 290,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialSquare(
                        onTap: () {
                          // Handle Facebook signup
                        },
                        child: Image.asset(
                          'assets/facebook_logo.png',
                          width: 45,
                          height: 45,
                        ),
                      ),
                      const SizedBox(width: 18),
                      SocialSquare(
                        onTap: () {
                          // Handle Google signup
                        },
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/login',
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
