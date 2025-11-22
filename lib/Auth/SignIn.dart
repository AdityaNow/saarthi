import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:health_care/Auth/SignUp.dart';
import 'package:health_care/Auth/forgot_password.dart';
import 'package:health_care/BottomNavBar/NavBarScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Please enter your password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Show snackbar message
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Sign in method with Supabase
  // Future<void> _signIn() async {
  //   // Validate inputs
  //   final emailError = _validateEmail(_emailController.text);
  //   final passwordError = _validatePassword(_passwordController.text);

  //   if (emailError != null) {
  //     _showMessage(emailError, isError: true);
  //     return;
  //   }
  //   if (passwordError != null) {
  //     _showMessage(passwordError, isError: true);
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     // Sign in with Supabase Auth
  //     final response = await Supabase.instance.client.auth.signInWithPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text,
  //     );

  //     setState(() {
  //       _isLoading = false;
  //     });

  //     if (response.user != null) {
  //       _showMessage('Welcome back!');

  //       // Small delay to show success message
  //       await Future.delayed(const Duration(milliseconds: 800));

  //       // Navigate to main screen
  //       if (mounted) {
  //         Navigator.pushAndRemoveUntil(
  //           context,
  //           MaterialPageRoute(builder: (context) => const MainScreen()),
  //           (Route<dynamic> route) => false,
  //         );
  //       }
  //     }
  //   } on AuthException catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     // Handle specific auth errors
  //     String errorMessage = 'Sign in failed';
  //     if (e.message.contains('Invalid login credentials')) {
  //       errorMessage = 'Invalid email or password';
  //     } else if (e.message.contains('Email not confirmed')) {
  //       errorMessage = 'Please verify your email first';
  //     } else if (e.message.contains('Invalid email')) {
  //       errorMessage = 'Please enter a valid email address';
  //     } else {
  //       errorMessage = e.message;
  //     }

  //     _showMessage(errorMessage, isError: true);
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     _showMessage('An error occurred. Please try again.', isError: true);
  //     print('Sign in error: $e');
  //   }
  // }
  Future<void> _saveUserSession(
    String userId,
    String email,
    String fullName,
    String password,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userEmail', email);

      await prefs.setString('userName', fullName);
      await prefs.setString(
        'password',
        password,
      ); // Save plain password for change password verification

      // Get user profile data
      final profile =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', userId)
              .single();

      if (profile != null) {
        await prefs.setString('userName', profile['full_name'] ?? '');
      }

      print('Session saved successfully');
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // Sign in method with Supabase
  // Future<void> _signIn() async {
  //   // Validate inputs
  //   final emailError = _validateEmail(_emailController.text);
  //   final passwordError = _validatePassword(_passwordController.text);

  //   if (emailError != null) {
  //     _showMessage(emailError, isError: true);
  //     return;
  //   }
  //   if (passwordError != null) {
  //     _showMessage(passwordError, isError: true);
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     // Sign in with Supabase Auth
  //     final response = await Supabase.instance.client.auth.signInWithPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text,
  //     );

  //     if (response.user != null) {
  //       // Save session to SharedPreferences
  //       await _saveUserSession(response.user!.id, response.user!.email!);

  //       setState(() {
  //         _isLoading = false;
  //       });

  //       _showMessage('Welcome back!');

  //       // Small delay to show success message
  //       await Future.delayed(const Duration(milliseconds: 800));

  //       // Navigate to main screen and remove all previous routes
  //       if (mounted) {
  //         Navigator.pushAndRemoveUntil(
  //           context,
  //           MaterialPageRoute(builder: (context) => const MainScreen()),
  //           (Route<dynamic> route) => false,
  //         );
  //       }
  //     }
  //   } on AuthException catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     // Handle specific auth errors
  //     String errorMessage = 'Sign in failed';
  //     if (e.message.contains('Invalid login credentials')) {
  //       errorMessage = 'Invalid email or password';
  //     } else if (e.message.contains('Email not confirmed')) {
  //       errorMessage = 'Please verify your email first';
  //     } else if (e.message.contains('Invalid email')) {
  //       errorMessage = 'Please enter a valid email address';
  //     } else {
  //       errorMessage = e.message;
  //     }

  //     _showMessage(errorMessage, isError: true);
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     _showMessage('An error occurred. Please try again.', isError: true);
  //     print('Sign in error: $e');
  //   }
  // }
  String sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      print("🚀 Starting SignIn...");

      // ✅ Fetch user from profiles table
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select('id, email, full_name, password')
              .eq('email', email)
              .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Email does not exist"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final storedHash = response['password'];
      final userId = response['id'];
      final fullName = response['full_name'] ?? 'User';

      // Hash entered password
      final enteredHash = sha256Hex(password);

      print("🔒 Stored Hash: $storedHash");
      print("🔑 Entered Hash: $enteredHash");

      // Check if password matches
      if (enteredHash != storedHash) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Invalid email or password"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print("✅ Password matched!");

      // ✅ Sign in with Supabase Auth
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // ✅ Save session in SharedPreferences
      await _saveUserSession(userId, email, fullName, password);
         Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (Route<dynamic> route) => false,
          );
       
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Welcome back!"),
          backgroundColor: Colors.green,
        ),
      );

      print("✅ SignIn successful! Session saved.");

      // Navigate to MainScreen
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => const MainScreen()),
      //   (route) => false,
      // );
    } catch (e) {
      print("❌ SignIn Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Google OAuth
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterdemo://login-callback/',
      );

      setState(() {
        _isLoading = false;
      });

      if (!response) {
        _showMessage('Google sign in cancelled', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Google sign in failed. Please try again.', isError: true);
      print('Google sign in error: $e');
    }
  }

  // Forgot password
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email address', isError: true);
      return;
    }

    final emailError = _validateEmail(email);
    if (emailError != null) {
      _showMessage(emailError, isError: true);
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showMessage('Password reset link sent to your email!');
    } on AuthException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage(
        'Failed to send reset email. Please try again.',
        isError: true,
      );
      print('Reset password error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      body: Column(
        children: [
          // Top Section with Green Gradient
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade600,
                  Colors.green.shade500,
                ],
              ),
            ),
            child: Stack(
              children: [
                _buildAnimatedBackground(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.medical_services_rounded,
                                size: 45,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to continue your health journey',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
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

          // Bottom White Card - Full Width
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Email Field
                      _buildHealthcareTextField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        prefixColor: Colors.green.shade600,
                      ),
                      const SizedBox(height: 18),

                      // Password Field
                      _buildHealthcareTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        prefixColor: Colors.green.shade600,
                        onTogglePassword: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    gradient:
                                        _rememberMe
                                            ? LinearGradient(
                                              colors: [
                                                Colors.green.shade600,
                                                Colors.green.shade500,
                                              ],
                                            )
                                            : null,
                                    color: _rememberMe ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          _rememberMe
                                              ? Colors.transparent
                                              : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child:
                                      _rememberMe
                                          ? const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Sign In Button
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade600.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _signIn(
                                context,
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                      : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // OR Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // Social Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Google',
                              icon: Icons.g_mobiledata_rounded,
                              iconColor: Colors.blue,
                              onPressed: _isLoading ? () {} : _signInWithGoogle,
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const SignUpScreen(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: -60,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthcareTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color prefixColor,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  prefixColor.withOpacity(0.1),
                  prefixColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: prefixColor, size: 20),
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:health_care/Auth/SignUp.dart';

// class SignInScreen extends StatefulWidget {
//   const SignInScreen({Key? key}) : super(key: key);

//   @override
//   State<SignInScreen> createState() => _SignInScreenState();
// }

// class _SignInScreenState extends State<SignInScreen>
//     with SingleTickerProviderStateMixin {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isPasswordVisible = false;
//   bool _rememberMe = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.2),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.green.shade600,
//       body: Column(
//         children: [
//           // Top Section with Green Gradient
//           Container(
//             height: 280,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Colors.green.shade700,
//                   Colors.green.shade600,
//                   Colors.green.shade500,
//                 ],
//               ),
//             ),
//             child: Stack(
//               children: [
//                 _buildAnimatedBackground(),
//                 SafeArea(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                     child: FadeTransition(
//                       opacity: _fadeAnimation,
//                       child: SlideTransition(
//                         position: _slideAnimation,
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Container(
//                               width: 90,
//                               height: 90,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 shape: BoxShape.circle,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.white.withOpacity(0.3),
//                                     blurRadius: 30,
//                                     spreadRadius: 8,
//                                   ),
//                                 ],
//                               ),
//                               child: Icon(
//                                 Icons.medical_services_rounded,
//                                 size: 45,
//                                 color: Colors.green.shade600,
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               'Welcome Back',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: -0.5,
//                               ),
//                             ),
//                             const SizedBox(height: 6),
//                             Text(
//                               'Sign in to continue your health journey',
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.9),
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Bottom White Card - Full Width
//           Expanded(
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(32),
//                   topRight: Radius.circular(32),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 20,
//                     offset: const Offset(0, -5),
//                   ),
//                 ],
//               ),
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 child: Padding(
//                   padding: const EdgeInsets.all(32),
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 10),
//                       // Email Field
//                       _buildHealthcareTextField(
//                         controller: _emailController,
//                         hintText: 'Email Address',
//                         icon: Icons.email_outlined,
//                         keyboardType: TextInputType.emailAddress,
//                         prefixColor: Colors.green.shade600,
//                       ),
//                       const SizedBox(height: 18),

//                       // Password Field
//                       _buildHealthcareTextField(
//                         controller: _passwordController,
//                         hintText: 'Password',
//                         icon: Icons.lock_outline_rounded,
//                         isPassword: true,
//                         isPasswordVisible: _isPasswordVisible,
//                         prefixColor: Colors.green.shade600,
//                         onTogglePassword: () {
//                           setState(() {
//                             _isPasswordVisible = !_isPasswordVisible;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Remember Me & Forgot Password
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               GestureDetector(
//                                 onTap: () {
//                                   setState(() {
//                                     _rememberMe = !_rememberMe;
//                                   });
//                                 },
//                                 child: AnimatedContainer(
//                                   duration: const Duration(milliseconds: 200),
//                                   width: 22,
//                                   height: 22,
//                                   decoration: BoxDecoration(
//                                     gradient:
//                                         _rememberMe
//                                             ? LinearGradient(
//                                               colors: [
//                                                 Colors.green.shade600,
//                                                 Colors.green.shade500,
//                                               ],
//                                             )
//                                             : null,
//                                     color: _rememberMe ? null : Colors.white,
//                                     borderRadius: BorderRadius.circular(6),
//                                     border: Border.all(
//                                       color:
//                                           _rememberMe
//                                               ? Colors.transparent
//                                               : Colors.grey.shade300,
//                                       width: 2,
//                                     ),
//                                   ),
//                                   child:
//                                       _rememberMe
//                                           ? const Icon(
//                                             Icons.check_rounded,
//                                             size: 14,
//                                             color: Colors.white,
//                                           )
//                                           : null,
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Text(
//                                 'Remember me',
//                                 style: TextStyle(
//                                   color: Colors.grey.shade700,
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           TextButton(
//                             onPressed: () => print('Forgot Password'),
//                             style: TextButton.styleFrom(
//                               padding: EdgeInsets.zero,
//                               minimumSize: const Size(0, 0),
//                               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             ),
//                             child: Text(
//                               'Forgot Password?',
//                               style: TextStyle(
//                                 color: Colors.green.shade600,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 28),

//                       // Sign In Button
//                       Container(
//                         width: double.infinity,
//                         height: 58,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               Colors.green.shade600,
//                               Colors.green.shade500,
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.green.shade600.withOpacity(0.4),
//                               blurRadius: 24,
//                               offset: const Offset(0, 12),
//                             ),
//                           ],
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             onTap: () => print('Sign In'),
//                             borderRadius: BorderRadius.circular(16),
//                             child: Center(
//                               child: Text(
//                                 'Sign In',
//                                 style: TextStyle(
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                   letterSpacing: 0.5,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 26),

//                       // OR Divider
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Divider(
//                               color: Colors.grey.shade300,
//                               thickness: 1,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: Text(
//                               'OR CONTINUE WITH',
//                               style: TextStyle(
//                                 color: Colors.grey.shade500,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w700,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Divider(
//                               color: Colors.grey.shade300,
//                               thickness: 1,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 26),

//                       // Social Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildSocialButton(
//                               label: 'Google',
//                               icon: Icons.g_mobiledata_rounded,
//                               iconColor: Colors.blue,
//                               onPressed: () => print('Google'),
//                             ),
//                           ),
//                           const SizedBox(width: 14),
//                         ],
//                       ),
//                       const SizedBox(height: 26),

//                       // Sign Up Link
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Don't have an account? ",
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 PageRouteBuilder(
//                                   pageBuilder:
//                                       (
//                                         context,
//                                         animation,
//                                         secondaryAnimation,
//                                       ) => const SignUpScreen(),
//                                   transitionsBuilder: (
//                                     context,
//                                     animation,
//                                     secondaryAnimation,
//                                     child,
//                                   ) {
//                                     return FadeTransition(
//                                       opacity: animation,
//                                       child: child,
//                                     );
//                                   },
//                                 ),
//                               );
//                             },
//                             child: Text(
//                               'Sign Up',
//                               style: TextStyle(
//                                 color: Colors.green.shade600,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnimatedBackground() {
//     return Stack(
//       children: [
//         Positioned(
//           top: -50,
//           right: -40,
//           child: Container(
//             width: 150,
//             height: 150,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: RadialGradient(
//                 colors: [
//                   Colors.white.withOpacity(0.15),
//                   Colors.white.withOpacity(0.05),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         Positioned(
//           top: 80,
//           left: -60,
//           child: Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: RadialGradient(
//                 colors: [
//                   Colors.white.withOpacity(0.1),
//                   Colors.white.withOpacity(0.02),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHealthcareTextField({
//     required TextEditingController controller,
//     required String hintText,
//     required IconData icon,
//     required Color prefixColor,
//     bool isPassword = false,
//     bool isPasswordVisible = false,
//     VoidCallback? onTogglePassword,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F9FA),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200, width: 1),
//       ),
//       child: TextField(
//         controller: controller,
//         obscureText: isPassword && !isPasswordVisible,
//         keyboardType: keyboardType,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF1F2937),
//         ),
//         decoration: InputDecoration(
//           hintText: hintText,
//           hintStyle: TextStyle(
//             color: Colors.grey.shade400,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//           prefixIcon: Container(
//             margin: const EdgeInsets.all(12),
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   prefixColor.withOpacity(0.1),
//                   prefixColor.withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: prefixColor, size: 20),
//           ),
//           suffixIcon:
//               isPassword
//                   ? IconButton(
//                     icon: Icon(
//                       isPasswordVisible
//                           ? Icons.visibility_rounded
//                           : Icons.visibility_off_rounded,
//                       color: Colors.grey.shade400,
//                       size: 20,
//                     ),
//                     onPressed: onTogglePassword,
//                   )
//                   : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 18,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSocialButton({
//     required String label,
//     required IconData icon,
//     required Color iconColor,
//     required VoidCallback onPressed,
//   }) {
//     return Container(
//       height: 56,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F9FA),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.grey.shade200, width: 1),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(14),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: iconColor, size: 26),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: Colors.grey.shade800,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
