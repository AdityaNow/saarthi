import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

// ✅ FULLY DEBUGGED OTP SERVICE
class OTPService {
  static final supabase = Supabase.instance.client;

  // Generate 6-digit OTP
  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send email via Supabase Edge Function
  static Future<bool> _sendEmailViaEdgeFunction(
  dynamic email,
  dynamic otp,
  dynamic type,
) async {
  try {
    final response = await supabase.functions.invoke(
      'resend-email',
      body: {'email': email, 'otp': otp, 'type': type},
    );

    print("📨 Raw Response = ${response.data}");

    // If response.data is Map, then read success
    if (response.data is Map && response.data['success'] == true) {
      return true;
    }

    // Otherwise treat as failure
    return false;
  } catch (e) {
    print('❌ Error sending email: $e');
    return false;
  }
}

  // Send OTP for Email Verification
  static Future<Map<String, dynamic>> sendEmailVerificationOTP(
    String email,
    String userId,
  ) async {
    try {
      final otp = generateOTP();
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(Duration(minutes: 10));

      print('═' * 50);
      print('📤 SENDING EMAIL VERIFICATION OTP');
      print('Email: $email');
      print('User ID: $userId');
      print('OTP: $otp');
      print('Current Time (UTC): ${now.toIso8601String()}');
      print('Expires At (UTC): ${expiresAt.toIso8601String()}');
      print('═' * 50);

      // Save OTP in database with explicit expiry
      await supabase.from('otp_verifications').insert({
        'user_id': userId,
        'email': email,
        'otp': otp,
        'otp_type': 'email_verification',
        'is_verified': false,
        'expires_at': expiresAt.toIso8601String(),
      });

      print('✅ OTP saved to database');

      // Send email
      final emailSent = await _sendEmailViaEdgeFunction(
        email,
        otp,
        'email_verification',
      );

      if (emailSent) {
        print('✅ OTP sent to $email: $otp');
        return {'success': true, 'message': 'OTP sent successfully to $email'};
      } else {
        print('⚠️ Email failed but OTP saved: $otp');
        return {
          'success': true,
          'message': 'OTP generated (check console for testing)',
          'otp': otp,
        };
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return {'success': false, 'message': 'Failed to send OTP: $e'};
    }
  }

  // Send OTP for Password Reset
  static Future<Map<String, dynamic>> sendPasswordResetOTP(String email) async {
    try {
      final user =
          await supabase
              .from('profiles')
              .select('id')
              .eq('email', email)
              .maybeSingle();

      if (user == null) {
        return {
          'success': false,
          'message': 'No account found with this email',
        };
      }

      final otp = generateOTP();
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(Duration(minutes: 10));

      print('═' * 50);
      print('📤 SENDING PASSWORD RESET OTP');
      print('Email: $email');
      print('User ID: ${user['id']}');
      print('OTP: $otp');
      print('Current Time (UTC): ${now.toIso8601String()}');
      print('Expires At (UTC): ${expiresAt.toIso8601String()}');
      print('═' * 50);

      // Save OTP in database with explicit expiry
      await supabase.from('otp_verifications').insert({
        'user_id': user['id'],
        'email': email,
        'otp': otp,
        'otp_type': 'password_reset',
        'is_verified': false,
        'expires_at': expiresAt.toIso8601String(),
      });

      print('✅ OTP saved to database');

      // Send email
      final emailSent = await _sendEmailViaEdgeFunction(
        email,
        otp,
        'password_reset',
      );

      if (emailSent) {
        print('✅ Password Reset OTP sent to $email: $otp');
        return {'success': true, 'message': 'OTP sent successfully to $email'};
      } else {
        print('⚠️ Email failed but OTP saved: $otp');
        return {
          'success': true,
          'message': 'OTP generated (check console for testing)',
          'otp': otp,
        };
      }
    } catch (e) {
      print('❌ Error sending password reset OTP: $e');
      return {'success': false, 'message': 'Failed to send OTP: $e'};
    }
  }

  // ✅ FULLY DEBUGGED VERIFY OTP
  static Future<Map<String, dynamic>> verifyOTP(
    String email,
    String otp,
    String otpType,
  ) async {
    try {
      final now = DateTime.now().toUtc();

      print('═' * 50);
      print('🔍 VERIFYING OTP');
      print('Email: $email');
      print('OTP Entered: $otp');
      print('OTP Type: $otpType');
      print('Current Time (UTC): ${now.toIso8601String()}');
      print('═' * 50);

      // First, get ALL OTPs for this email to debug
      final allOtps = await supabase
          .from('otp_verifications')
          .select()
          .eq('email', email)
          .eq('otp_type', otpType)
          .order('created_at', ascending: false);

      print('📋 Found ${allOtps.length} OTP(s) for this email:');
      for (int i = 0; i < allOtps.length; i++) {
        final record = allOtps[i];
        final expiresAt = DateTime.parse(record['expires_at']);
        final isExpired = now.isAfter(expiresAt);

        print('  ${i + 1}. OTP: ${record['otp']}');
        print('     Verified: ${record['is_verified']}');
        print('     Created: ${record['created_at']}');
        print('     Expires: ${record['expires_at']}');
        print('     Is Expired: $isExpired');
        print('     Match: ${record['otp'] == otp}');
        print('');
      }

      // Try to find matching OTP WITHOUT expiry check first
      final matchingOtp =
          await supabase
              .from('otp_verifications')
              .select()
              .eq('email', email)
              .eq('otp', otp)
              .eq('otp_type', otpType)
              .eq('is_verified', false)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (matchingOtp == null) {
        print(
          '❌ No matching OTP found (might be already verified or wrong OTP)',
        );
        return {'success': false, 'message': 'Invalid OTP'};
      }

      print('✅ Found matching OTP!');

      // Check if expired
      final expiresAt = DateTime.parse(matchingOtp['expires_at']);
      if (now.isAfter(expiresAt)) {
        print('❌ OTP has expired');
        print('   Expired at: ${expiresAt.toIso8601String()}');
        print('   Current time: ${now.toIso8601String()}');
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new one.',
        };
      }

      print('✅ OTP is valid and not expired!');

      // Mark as verified
      await supabase
          .from('otp_verifications')
          .update({'is_verified': true, 'verified_at': now.toIso8601String()})
          .eq('id', matchingOtp['id']);

      print('✅ OTP marked as verified');
      print('═' * 50);

      return {
        'success': true,
        'message': 'OTP verified successfully',
        'user_id': matchingOtp['user_id'],
      };
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      print('Stack trace: ${StackTrace.current}');
      return {'success': false, 'message': 'Failed to verify OTP: $e'};
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOTP(
    String email,
    String otpType,
  ) async {
    try {
      print('🔄 Resending OTP for $email');

      // Invalidate old OTPs
      await supabase
          .from('otp_verifications')
          .update({'is_verified': true})
          .eq('email', email)
          .eq('otp_type', otpType)
          .eq('is_verified', false);

      print('✅ Old OTPs invalidated');

      // Generate new OTP
      if (otpType == 'email_verification') {
        final user =
            await supabase
                .from('profiles')
                .select('id')
                .eq('email', email)
                .single();
        return await sendEmailVerificationOTP(email, user['id']);
      } else {
        return await sendPasswordResetOTP(email);
      }
    } catch (e) {
      print('❌ Error resending OTP: $e');
      return {'success': false, 'message': 'Failed to resend OTP: $e'};
    }
  }
}

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String otpType; // 'email_verification' or 'password_reset'
  final Function(bool success, String? userId) onVerificationComplete;

  const OTPVerificationScreen({
    Key? key,
    required this.email,
    required this.otpType,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  String _getOTP() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOTP() async {
    final otp = _getOTP();

    if (otp.length != 6) {
      _showMessage('Please enter complete OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await OTPService.verifyOTP(
        widget.email,
        otp,
        widget.otpType,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showMessage('OTP verified successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onVerificationComplete(true, result['user_id']);
      } else {
        _showMessage(result['message'] ?? 'Verification failed', isError: true);
        _clearOTP();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Verification failed. Please try again.', isError: true);
      _clearOTP();
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() => _isResending = true);

    try {
      final result = await OTPService.resendOTP(widget.email, widget.otpType);

      setState(() => _isResending = false);

      if (result['success']) {
        _showMessage('OTP resent successfully!');
        _startResendTimer();
        _clearOTP();
      } else {
        _showMessage(
          result['message'] ?? 'Failed to resend OTP',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isResending = false);
      _showMessage('Failed to resend OTP', isError: true);
    }
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      body: Column(
        children: [
          // Top Section
          Container(
            height: 250,
            decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              //   colors: [
              //     Colors.green.shade700,
              //     Colors.green.shade600,
              //     Colors.green.shade500,
              //   ],
              // ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
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
                        Icons.mail_outline_rounded,
                        size: 30,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Verify OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Enter the 6-digit code sent to',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom White Card
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
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // OTP Input Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return _buildOTPBox(index);
                      }),
                    ),

                    const SizedBox(height: 40),

                    // Verify Button
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
                          onTap: _isLoading ? null : _verifyOTP,
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
                                      'Verify OTP',
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

                    const SizedBox(height: 30),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        _isResending
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : GestureDetector(
                              onTap: _resendTimer > 0 ? null : _resendOTP,
                              child: Text(
                                _resendTimer > 0
                                    ? 'Resend in ${_resendTimer}s'
                                    : 'Resend OTP',
                                style: TextStyle(
                                  color:
                                      _resendTimer > 0
                                          ? Colors.grey.shade400
                                          : Colors.green.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Back button
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 50,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _otpControllers[index].text.isNotEmpty
                  ? Colors.green.shade600
                  : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.length == 1) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _verifyOTP();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);

    if (emailError != null) {
      _showMessage(emailError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await OTPService.sendPasswordResetOTP(email);

      setState(() => _isLoading = false);

      if (result['success']) {
        _showMessage('OTP sent to your email!');

        // Navigate to OTP verification screen
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OTPVerificationScreen(
                    email: email,
                    otpType: 'password_reset',
                    onVerificationComplete: (success, userId) {
                      if (success && userId != null) {
                        // Navigate to Reset Password Screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ResetPasswordScreen(
                                  userId: userId,
                                  email: email,
                                ),
                          ),
                        );
                      }
                    },
                  ),
            ),
          );
        }
      } else {
        _showMessage(result['message'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Something went wrong. Please try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      body: Column(
        children: [
          // Top Section
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                        Icons.lock_reset_rounded,
                        size: 45,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Don\'t worry! We\'ll send you a verification code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom White Card
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
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    Text(
                      'Enter your email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'We will send a verification code to this email',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
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
                                  Colors.green.shade600.withOpacity(0.1),
                                  Colors.green.shade600.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                          ),
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
                    ),

                    const SizedBox(height: 30),

                    // Send OTP Button
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
                          onTap: _isLoading ? null : _sendOTP,
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
                                      'Send Verification Code',
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

                    const SizedBox(height: 30),

                    // Back to Login
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Login'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String userId;
  final String email;

  const ResetPasswordScreen({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

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

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please fill all fields', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showMessage('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('═' * 50);
      print('🔄 RESETTING PASSWORD');
      print('User ID: ${widget.userId}');
      print('Email: ${widget.email}');
      print('═' * 50);

      // 1️⃣ Hash the new password
      final encryptedPassword = sha256Hex(newPassword);
      print('🔐 Encrypted Password: $encryptedPassword');

      // // 2️⃣ Update password in Supabase Auth using Edge Function
      // final functionUrl =
      //     "https://kwrskwqmbbhutblilonq.supabase.co/functions/v1/resend-email";

      // final response = await http.post(
      //   Uri.parse(functionUrl),
      //   headers: {
      //     "Content-Type": "application/json",
      //     "Authorization":
      //         "Bearer ${supabase.auth.currentSession?.accessToken}",
      //   },

      //   body: jsonEncode({
      //     "user_id": widget.userId,
      //     "new_password": newPassword,
      //   }),
      // );

      // if (response.statusCode == 200) {
      //   print('✅ Auth password updated via Edge Function');
      // } else {
      //   print('⚠️ Edge Function call failed: ${response.body}');
      //   // Continue anyway to update profiles table
      // }
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      // 3️⃣ Update password in profiles table (hashed)
      await supabase
          .from('profiles')
          .update({'password': encryptedPassword})
          .eq('id', widget.userId);

      print('✅ Profile password updated!');
      print('═' * 50);

      setState(() => _isLoading = false);

      _showMessage('Password reset successfully!');

      // Navigate back to login after 1.5 seconds
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error resetting password: $e');
      _showMessage('Failed to reset password', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      body: Column(
        children: [
          // Top Section
          Container(
            height: 250,
            decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              //   colors: [
              //     Colors.green.shade700,
              //     Colors.green.shade600,
              //     Colors.green.shade500,
              //   ],
              // ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
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
                        Icons.vpn_key_rounded,
                        size: 40,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new strong password',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom White Card
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
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildPasswordField(
                      controller: _newPasswordController,
                      hintText: 'Enter new password (min 6 characters)',
                      isVisible: _isNewPasswordVisible,
                      toggleVisibility: () {
                        setState(
                          () => _isNewPasswordVisible = !_isNewPasswordVisible,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm your new password',
                      isVisible: _isConfirmPasswordVisible,
                      toggleVisibility: () {
                        setState(
                          () =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible,
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Reset Password Button
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
                          onTap: _isLoading ? null : _resetPassword,
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
                                      'Reset Password',
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
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
                  Colors.green.shade600.withOpacity(0.1),
                  Colors.green.shade600.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: Colors.green.shade600,
              size: 20,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
            onPressed: toggleVisibility,
          ),
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
}

class ChangePasswordScreen extends StatefulWidget {
  final String? userId;

  const ChangePasswordScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _printDebugInfo();
  }

  // Debug function to print saved password
  Future<void> _printDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('password') ?? 'NOT FOUND';
    final savedEmail = prefs.getString('email') ?? 'NOT FOUND';
    final userId = prefs.getString('user_id') ?? 'NOT FOUND';

    print('═' * 50);
    print('🔍 DEBUG INFO:');
    print('User ID: $userId');
    print('Saved Email: $savedEmail');
    print('Saved Password: "$savedPassword"');
    print('Password Length: ${savedPassword.length}');
    print('═' * 50);
  }

  final supabase = Supabase.instance.client;

  String sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> updatePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // ✅ Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // ✅ Check if new passwords match
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New password and confirm password do not match"),
        ),
      );
      return;
    }

    // ✅ Check password length
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print("🔍 Checking logged-in user ID...");
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User not logged in")));
        return;
      }

      print("🔍 Checking user: $userId");

      // Fetch user from Supabase
      final user =
          await supabase
              .from('profiles')
              .select('id, password')
              .eq('id', userId)
              .maybeSingle();

      if (user == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User not found")));
        return;
      }

      final dbPassword = user['password']; // stored password in DB
      print("🔒 Stored Password: $dbPassword");

      // 🔐 Encrypt entered current password
      final encryptedEnteredPassword = sha256Hex(currentPassword);
      print("🔑 Entered (SHA256 HEX): $encryptedEnteredPassword");

      // ❌ Incorrect current password
      if (encryptedEnteredPassword != dbPassword) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Current password is incorrect"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print("✅ Password matched! Updating password...");

      // 🔐 Encrypt new password
      final newEncryptedPassword = sha256Hex(newPassword);

      // Update password in Supabase
      await supabase
          .from('profiles') // ✅ USE THIS
          .update({'password': newEncryptedPassword})
          .eq('id', userId);
      // await supabase
      //     .from('Users')
      //     .update({'password': newEncryptedPassword})
      //     .eq('id', userId);

      // Update password in SharedPreferences
      await prefs.setString('password', newPassword);

      setState(() => isLoading = false);

      print("✅ Password updated successfully!");

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Password updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear all text fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      // Navigate back to home page after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // Pop until home screen (adjust route name as per your app)
          Navigator.of(context).popUntil((route) => route.isFirst);

          // OR if you have named routes, use this:
          // Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Error updating password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.backgroundC,
      appBar: AppBar(
        // backgroundColor: AppColors.backgroundC,
        elevation: 0,
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                Text(
                  'Secure Your Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your current password and choose a new one',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 40),

                _buildPasswordField(
                  label: 'Current Password',
                  controller: currentPasswordController,
                  isVisible: isCurrentPasswordVisible,
                  toggleVisibility: () {
                    setState(
                      () =>
                          isCurrentPasswordVisible = !isCurrentPasswordVisible,
                    );
                  },
                  hintText: 'Enter your current password',
                ),

                const SizedBox(height: 24),

                _buildPasswordField(
                  label: 'New Password',
                  controller: newPasswordController,
                  isVisible: isNewPasswordVisible,
                  toggleVisibility: () {
                    setState(
                      () => isNewPasswordVisible = !isNewPasswordVisible,
                    );
                  },
                  hintText: 'Enter new password (min 6 characters)',
                ),

                const SizedBox(height: 24),

                _buildPasswordField(
                  label: 'Confirm New Password',
                  controller: confirmPasswordController,
                  isVisible: isConfirmPasswordVisible,
                  toggleVisibility: () {
                    setState(
                      () =>
                          isConfirmPasswordVisible = !isConfirmPasswordVisible,
                    );
                  },
                  hintText: 'Confirm your new password',
                ),

                const SizedBox(height: 40),

                // Change Password Button
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    // gradient: LinearGradient(
                    //   colors: [
                    //   AppColors.ProgressB,
                    //     AppColors.ProgressB.withOpacity(0.8),
                    //   ],
                    // ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        // color: AppColors.ProgressB.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : updatePassword,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : const Text(
                                  'Change Password',
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

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String hintText = '••••••••',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
