// import 'package:flutter/material.dart';
// import 'package:health_care/BottomNavBar/NavBarScreen.dart';
// import 'package:health_care/WelCome/WelComeScreen.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// const supabaseUrl = 'https://kwrskwqmbbhutblilonq.supabase.co';
// const supabaseKey =
//     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3cnNrd3FtYmJodXRibGlsb25xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNDkwMjksImV4cCI6MjA3ODkyNTAyOX0.OeymxhLWXzoPspCABXg-0gwbPOn8841duruOas5JDXk';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Supabase Initialize karo
//   await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

//   runApp(const HealthcareApp());
// }

// class HealthcareApp extends StatelessWidget {
//   const HealthcareApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Poppins'),
//       // home: const AutoScrollOnboardingScreen(),
//       home: FutureBuilder(
//         future: _checkAuthStatus(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }
          
//           // If user is logged in, go to MainScreen, else SignInScreen
//           final isLoggedIn = snapshot.data as bool? ?? false;
//           return isLoggedIn ? const MainScreen() : const AutoScrollOnboardingScreen();
//         },
//       ),
//     );
//   }
   
//   Future<bool> _checkAuthStatus() async {
//     final session = Supabase.instance.client.auth.currentSession;
//     return session != null;
// }
// }
import 'package:flutter/material.dart';
import 'package:health_care/BottomNavBar/NavBarScreen.dart';
import 'package:health_care/WelCome/WelComeScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supabaseUrl = 'https://kwrskwqmbbhutblilonq.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3cnNrd3FtYmJodXRibGlsb25xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNDkwMjksImV4cCI6MjA3ODkyNTAyOX0.OeymxhLWXzoPspCABXg-0gwbPOn8841duruOas5JDXk';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialize karo
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const HealthcareApp());
}

class HealthcareApp extends StatelessWidget {
  const HealthcareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Poppins'),
      home: FutureBuilder(
        future: _checkAuthStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // If user is logged in, go to MainScreen, else onboarding
          final isLoggedIn = snapshot.data as bool? ?? false;
          return isLoggedIn ? const MainScreen() : const AutoScrollOnboardingScreen();
        },
      ),
    );
  }
   
  // SharedPreferences se check karo ki user logged in hai ya nahi
  Future<bool> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      print('Checking auth status: $isLoggedIn');
      
      // Optional: Supabase session bhi check kar sakte ho as backup
      // final session = Supabase.instance.client.auth.currentSession;
      
      return isLoggedIn;
    } catch (e) {
      print('Error checking auth status: $e');
      return false;
    }
  }
}