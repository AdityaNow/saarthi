import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionManager {
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      // Also check Supabase session
      final supabaseSession = Supabase.instance.client.auth.currentSession;
      
      return isLoggedIn && supabaseSession != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get user data
  static Future<Map<String, String?>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'userId': prefs.getString('userId'),
        'userEmail': prefs.getString('userEmail'),
        'userName': prefs.getString('userName'),
      };
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }

  // Save user session
  static Future<void> saveSession({
    required String userId,
    required String email,
    String? name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userEmail', email);
      if (name != null) {
        await prefs.setString('userName', name);
      }
      print('Session saved successfully');
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // Clear session (Logout)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await Supabase.instance.client.auth.signOut();
      print('Session cleared successfully');
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  // Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userEmail');
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  // Get user name
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userName');
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }
}