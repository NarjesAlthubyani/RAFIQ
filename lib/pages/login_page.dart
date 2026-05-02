import 'package:flutter/material.dart';
import 'package:rafiq/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null && mounted) {
        // Success! Navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double sidePadding = 26;
    final double contentWidth = size.width - (sidePadding * 2);
    final double fieldHeight = 54;
    final double baseTop = size.height * 0.45;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/riyadh.jpg', fit: BoxFit.cover),

          // Light overlay
          Container(color: AppColors.black.withOpacity(0.08)),

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
                      color: AppColors.white,
                    ),
                  ),
                ),

                // Email field
                Positioned(
                  top: baseTop,
                  left: sidePadding,
                  right: sidePadding,
                  child: SizedBox(
                    width: contentWidth,
                    child: AuthInputField(
                      hint: 'Email',
                      obscure: false,
                      controller: _emailController,
                    ),
                  ),
                ),

                // Password field
                Positioned(
                  top: baseTop + fieldHeight + 16,
                  left: sidePadding,
                  right: sidePadding,
                  child: SizedBox(
                    width: contentWidth,
                    child: AuthInputField(
                      hint: 'Password',
                      obscure: true,
                      controller: _passwordController,
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
                              color: AppColors.white.withOpacity(1.0),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                // Handle forgot password
                                _showForgotPasswordDialog();
                              },
                              child: const Text(
                                'Click me',
                                style: TextStyle(
                                  color: AppColors.white,
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
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : const Text(
                                'Log in',
                                style: TextStyle(
                                  color: AppColors.white,
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
                          color: AppColors.white.withOpacity(0.28),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.60),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.white.withOpacity(0.28),
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
                      SocialSquare(
                        onTap: () {
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
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't Have An Account? ",
                            style: TextStyle(
                              color: AppColors.white.withOpacity(1.0),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppColors.white,
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

  void _showForgotPasswordDialog() {
    // Implement forgot password
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Please contact support or check your email for password reset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}