import 'package:flutter/material.dart';
import 'package:rafiq/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (response.user != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please check your email for confirmation.'),
            backgroundColor: AppColors.accent,
          ),
        );
        
        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
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

    const sidePadding = 26.0;
    final baseTop = size.height * 0.45;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/riyadh.jpg', fit: BoxFit.cover),
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
                  child: AuthInputField(
                    hint: 'Email',
                    obscure: false,
                    controller: _emailController,
                  ),
                ),

                // Name field
                Positioned(
                  top: baseTop + 70,
                  left: sidePadding,
                  right: sidePadding,
                  child: AuthInputField(
                    hint: 'Name',
                    obscure: false,
                    controller: _nameController,
                  ),
                ),

                // Password field
                Positioned(
                  top: baseTop + 140,
                  left: sidePadding,
                  right: sidePadding,
                  child: AuthInputField(
                    hint: 'Password',
                    obscure: true,
                    controller: _passwordController,
                  ),
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
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppColors.white,
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                color: AppColors.white,
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