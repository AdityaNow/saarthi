// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:health_care/Graph/GraphScreen.dart';
// import 'package:health_care/Home/HomeScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class MainScreen extends StatefulWidget {
//   const MainScreen({Key? key}) : super(key: key);

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   int _currentIndex = 0;
//   List<HealthEntry> sugarEntries = [];
//   List<BPEntry> bpEntries = [];
//   List<NoteEntry> notes = [];

//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }

//   Future<void> loadData() async {
//     final prefs = await SharedPreferences.getInstance();

//     final sugarJson = prefs.getString('sugar_entries');
//     if (sugarJson != null) {
//       final List<dynamic> decoded = json.decode(sugarJson);
//       setState(() {
//         sugarEntries = decoded.map((e) => HealthEntry.fromJson(e)).toList();
//       });
//     }

//     final bpJson = prefs.getString('bp_entries');
//     if (bpJson != null) {
//       final List<dynamic> decoded = json.decode(bpJson);
//       setState(() {
//         bpEntries = decoded.map((e) => BPEntry.fromJson(e)).toList();
//       });
//     }

//     final notesJson = prefs.getString('notes');
//     if (notesJson != null) {
//       final List<dynamic> decoded = json.decode(notesJson);
//       setState(() {
//         notes = decoded.map((e) => NoteEntry.fromJson(e)).toList();
//       });
//     }
//   }

//   Future<void> saveSugarEntries() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = json.encode(
//       sugarEntries.map((e) => e.toJson()).toList(),
//     );
//     await prefs.setString('sugar_entries', jsonString);
//   }

//   Future<void> saveBPEntries() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = json.encode(bpEntries.map((e) => e.toJson()).toList());
//     await prefs.setString('bp_entries', jsonString);
//   }

//   Future<void> saveNotes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = json.encode(notes.map((e) => e.toJson()).toList());
//     await prefs.setString('notes', jsonString);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> screens = [
//       HomeScreen(
//       ),
//       GraphScreen(sugarEntries: [], bpEntries: [],),
//     ];

//     return Scaffold(
//       body: screens[_currentIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.2),
//               blurRadius: 10,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _currentIndex,
//           onTap: (index) {
//             setState(() {
//               _currentIndex = index;
//             });
//           },
//           selectedItemColor: Colors.green[600],
//           unselectedItemColor: Colors.grey[400],
//           selectedFontSize: 12,
//           unselectedFontSize: 12,
//           type: BottomNavigationBarType.fixed,
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home_outlined),
//               activeIcon: Icon(Icons.home),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.show_chart),
//               activeIcon: Icon(Icons.show_chart),
//               label: 'Graph',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class HealthEntry {
//   final String id;  // Changed from int to String
//   final double value;
//   final String date;
//   final int? timestamp;

//   HealthEntry({
//     required this.id,
//     required this.value,
//     required this.date,
//     this.timestamp,
//   });

//   factory HealthEntry.fromJson(Map<String, dynamic> json) {
//     return HealthEntry(
//       id: json['id']?.toString() ?? '',
//       value: (json['value'] as num).toDouble(),
//       date: json['date'] as String,
//       timestamp: json['timestamp'] != null
//           ? (json['timestamp'] is int
//               ? json['timestamp'] as int
//               : (json['timestamp'] as num).toInt())
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'value': value,
//         'date': date,
//         'timestamp': timestamp,
//       };
// }

// class BPEntry {
//   final String id;  // Changed from int to String
//   final double systolic;
//   final double diastolic;
//   final String date;
//   final int? timestamp;

//   BPEntry({
//     required this.id,
//     required this.systolic,
//     required this.diastolic,
//     required this.date,
//     this.timestamp,
//   });

//   factory BPEntry.fromJson(Map<String, dynamic> json) {
//     return BPEntry(
//       id: json['id']?.toString() ?? '',
//       systolic: (json['systolic'] as num).toDouble(),
//       diastolic: (json['diastolic'] as num).toDouble(),
//       date: json['date'] as String,
//       timestamp: json['timestamp'] != null
//           ? (json['timestamp'] is int
//               ? json['timestamp'] as int
//               : (json['timestamp'] as num).toInt())
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'systolic': systolic,
//         'diastolic': diastolic,
//         'date': date,
//         'timestamp': timestamp,
//       };
// }

// class NoteEntry {
//   final String id;  // Changed from int to String
//   final String text;
//   final String date;
//   final int? timestamp;

//   NoteEntry({
//     required this.id,
//     required this.text,
//     required this.date,
//     this.timestamp,
//   });

//   factory NoteEntry.fromJson(Map<String, dynamic> json) {
//     return NoteEntry(
//       id: json['id']?.toString() ?? '',
//       text: json['text'] as String,
//       date: json['date'] as String,
//       timestamp: json['timestamp'] != null
//           ? (json['timestamp'] is int
//               ? json['timestamp'] as int
//               : (json['timestamp'] as num).toInt())
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'text': text,
//         'date': date,
//         'timestamp': timestamp,
//       };
// }
// // Main Screen with Bottom Navigation
// MainScreen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_care/Graph/GraphScreen.dart';
import 'package:health_care/Home/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // State variables for dynamic data
  List<HealthEntry> sugarEntries = [];
  List<BPEntry> bpEntries = [];
  List<HealthMetricEntry> HeartRateEntries = [];
  List<HealthMetricEntry> TempratureEntries = [];
  List<HealthMetricEntry> WeightEntries = [];
  List<HealthMetricEntry> heightEntries = [];
  List<CBCEntry> cbcEntries = [];
  List<HealthMetricEntry> wbcEntries = [];
  List<HealthMetricEntry> pulseEntries = [];
  List<NoteEntry> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // _fetchEntries();
    // _loadNotes(); // Start fetching data from Supabase on screen load
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch both lists simultaneously
      await Future.wait([
        _loadSugarEntries(),
        _loadBPEntries(),
        // _loadNotes(), // Agar notes ka bhi data load karna ho
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
      print('Combined Fetch Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // === SUPABASE INSERT FUNCTIONS (Updated to insert and reload/optimistic update) ===
  Future<void> _addSugarEntry(
    double value,
    DateTime date,
    String timeOfDay,
    String mealTime, // New parameter for pre-meal/post-meal
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Check if entry already exists for this date, time of day, and meal time
      final existingEntries = await Supabase.instance.client
          .from('health_entries')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', formattedDate)
          .eq('time_of_day', timeOfDay)
          .eq('meal_time', mealTime);

      if (existingEntries.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You already have a $mealTime sugar entry for this date!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check total entries for the day (now allowing 4: morning pre/post + evening pre/post)
      final totalEntries = await Supabase.instance.client
          .from('health_entries')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', formattedDate);

      if (totalEntries.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only add 2 sugar entries per day'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final dataToInsert = {
        'user_id': userId,
        'value': value,
        'entry_date': formattedDate,
        'time_of_day': timeOfDay,
        'meal_time': mealTime, // Add meal time
      };

      await Supabase.instance.client
          .from('health_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sugar entry   $mealTime added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadSugarEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print('Error adding sugar entry: $e');
    }
  }

  Future<void> _loadSugarEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('health_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .order('time_of_day', ascending: true)
          .order(
            'meal_time',
            ascending: true,
          ); // Pre-meal first, then post-meal

      setState(() {
        sugarEntries =
            (response as List)
                .map(
                  (entry) => HealthEntry(
                    id: entry['id'].toString(),
                    value: (entry['value'] as num).toDouble(),
                    date: entry['entry_date'],
                    timestamp:
                        entry['created_at'] != null
                            ? DateTime.parse(
                              entry['created_at'],
                            ).millisecondsSinceEpoch
                            : DateTime.now().millisecondsSinceEpoch,
                    timeOfDay: entry['time_of_day'],
                    mealTime: entry['meal_time'], // Include meal time
                  ),
                )
                .toList();
      });
    } catch (e) {
      print('Error loading sugar entries: $e');
    }
  }

  Future<void> _addBPEntry(
    double systolic,
    double diastolic,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Check if entry already exists for this date and time of day
      final existingEntries = await Supabase.instance.client
          .from('bp_entries')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', formattedDate)
          .eq('time_of_day', timeOfDay);

      if (existingEntries.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You already have a $timeOfDay BP entry for this date!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check total entries for the day
      final totalEntries = await Supabase.instance.client
          .from('bp_entries')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', formattedDate);

      if (totalEntries.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only add 2 BP entries per day!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final dataToInsert = {
        'user_id': userId,
        'systolic': systolic.round(),
        'diastolic': diastolic.round(),
        'entry_date': formattedDate,
        'time_of_day': timeOfDay, // Add time of day
      };

      await Supabase.instance.client
          .from('bp_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blood pressure ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadBPEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print('Error adding BP entry: $e');
    }
  }

  Future<void> _loadBPEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('bp_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .order('time_of_day', ascending: true); // Morning first

      setState(() {
        bpEntries =
            (response as List)
                .map(
                  (entry) => BPEntry(
                    id: entry['id'].toString(),
                    systolic: (entry['systolic'] as num).toDouble(),
                    diastolic: (entry['diastolic'] as num).toDouble(),
                    date: entry['entry_date'],
                    timestamp:
                        entry['created_at'] != null
                            ? DateTime.parse(
                              entry['created_at'],
                            ).millisecondsSinceEpoch
                            : DateTime.now().millisecondsSinceEpoch,
                    timeOfDay: entry['time_of_day'], // Include time of day
                  ),
                )
                .toList();
      });
    } catch (e) {
      print('Error loading BP entries: $e');
    }
  }

  Future<void> _addHeartRateEntry(
    double value,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      // Check if entry already exists for this date and time of day
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // final existingEntries = await Supabase.instance.client
      //     .from('heart_rate_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate)
      //     .eq('time_of_day', timeOfDay);

      // if (existingEntries.isNotEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('You already have a $timeOfDay entry for this date!'),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      //   return;
      // }

      // // Check total entries for the day
      // final totalEntries = await Supabase.instance.client
      //     .from('heart_rate_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate);

      // if (totalEntries.length >= 2) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You can only add 2 entries per day!'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      final dataToInsert = {
        'user_id': userId,
        'value': value.round(),
        'entry_date': formattedDate,
        'time_of_day': timeOfDay, // Add time of day
      };

      await Supabase.instance.client
          .from('heart_rate_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Heart rate ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadHeartRateEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error adding heart rate: $e");
    }
  }

  Future<void> _loadHeartRateEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('heart_rate_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: true)
          .order('time_of_day', ascending: true); // Morning first, then evening

      final List<HealthMetricEntry> fetched =
          (response as List)
              .map(
                (entry) => HealthMetricEntry(
                  id: entry['id'].toString(),
                  value: (entry['value'] as num).toDouble(),
                  date: entry['entry_date'],
                  timestamp:
                      entry['created_at'] != null
                          ? DateTime.parse(
                            entry['created_at'],
                          ).millisecondsSinceEpoch
                          : null,
                  timeOfDay: entry['time_of_day'], // Include time of day
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          HeartRateEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
    }
  }

  Future<void> _addPulseEntry(
    double value,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Check if entry already exists for this date and time of day
      // final existingEntries = await Supabase.instance.client
      //     .from('pulse_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate)
      //     .eq('time_of_day', timeOfDay);

      // if (existingEntries.isNotEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         'You already have a $timeOfDay pulse entry for this date!',
      //       ),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      //   return;
      // }

      // // Check total entries for the day
      // final totalEntries = await Supabase.instance.client
      //     .from('pulse_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate);

      // if (totalEntries.length >= 2) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You can only add 2 pulse entries per day!'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      final dataToInsert = {
        'user_id': userId,
        'value': value.round(),
        'entry_date': formattedDate,
        'time_of_day': timeOfDay,
      };

      await Supabase.instance.client
          .from('pulse_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pulse rate ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadPulseEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print('Error adding pulse entry: $e');
    }
  }

  // Load Pulse Entries
  Future<void> _loadPulseEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('pulse_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: true)
          .order('time_of_day', ascending: true);

      final List<HealthMetricEntry> fetched =
          (response as List)
              .map(
                (entry) => HealthMetricEntry(
                  id: entry['id'].toString(),
                  value: (entry['value'] as num).toDouble(),
                  date: entry['entry_date'],
                  timestamp:
                      entry['created_at'] != null
                          ? DateTime.parse(
                            entry['created_at'],
                          ).millisecondsSinceEpoch
                          : null,
                  timeOfDay: entry['time_of_day'],
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          pulseEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading pulse entries: $e');
    }
  }

  Future<void> _addTempratureEntry(
    double value,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      // Check if entry already exists for this date and time of day
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // final existingEntries = await Supabase.instance.client
      //     .from('temprature_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate)
      //     .eq('time_of_day', timeOfDay);

      // if (existingEntries.isNotEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('You already have a $timeOfDay entry for this date!'),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      //   return;
      // }

      // Check total entries for the day
      // final totalEntries = await Supabase.instance.client
      //     .from('temprature_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate);

      // if (totalEntries.length >= 2) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You can only add 2 entries per day!'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      final dataToInsert = {
        'user_id': userId,
        'value': value.round(),
        'entry_date': formattedDate,
        'time_of_day': timeOfDay, // Add time of day
      };

      await Supabase.instance.client
          .from('temprature_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Temprature added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadTempratureEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error adding heart rate: $e");
    }
  }

  Future<void> _loadTempratureEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('temprature_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: true)
          .order('time_of_day', ascending: true); // Morning first, then evening

      final List<HealthMetricEntry> fetched =
          (response as List)
              .map(
                (entry) => HealthMetricEntry(
                  id: entry['id'].toString(),
                  value: (entry['value'] as num).toDouble(),
                  date: entry['entry_date'],
                  timestamp:
                      entry['created_at'] != null
                          ? DateTime.parse(
                            entry['created_at'],
                          ).millisecondsSinceEpoch
                          : null,
                  timeOfDay: entry['time_of_day'], // Include time of day
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          TempratureEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
    }
  }

  Future<void> _addWeightEntry(
    double value,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      // Check if entry already exists for this date and time of day
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // final existingEntries = await Supabase.instance.client
      //     .from('weight')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate)
      //     .eq('time_of_day', timeOfDay);

      // if (existingEntries.isNotEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('You already have a $timeOfDay entry for this date!'),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      //   return;
      // }

      // // Check total entries for the day
      // final totalEntries = await Supabase.instance.client
      //     .from('weight')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate);

      // if (totalEntries.length >= 2) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You can only add 2 entries per day!'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      final dataToInsert = {
        'user_id': userId,
        'value': value.round(),
        'entry_date': formattedDate,
        'time_of_day': timeOfDay, // Add time of day
      };

      await Supabase.instance.client
          .from('weight')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weight ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadWeightEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error adding heart rate: $e");
    }
  }

  Future<void> _loadWeightEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('weight')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: true)
          .order('time_of_day', ascending: true); // Morning first, then evening

      final List<HealthMetricEntry> fetched =
          (response as List)
              .map(
                (entry) => HealthMetricEntry(
                  id: entry['id'].toString(),
                  value: (entry['value'] as num).toDouble(),
                  date: entry['entry_date'],
                  timestamp:
                      entry['created_at'] != null
                          ? DateTime.parse(
                            entry['created_at'],
                          ).millisecondsSinceEpoch
                          : null,
                  timeOfDay: entry['time_of_day'], // Include time of day
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          WeightEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
    }
  }

  Future<void> _addHeightEntry(
    double value,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      // Check if entry already exists for this date and time of day
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // final existingEntries = await Supabase.instance.client
      //     .from('height')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate)
      //     .eq('time_of_day', timeOfDay);

      // if (existingEntries.isNotEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('You already have a $timeOfDay entry for this date!'),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      //   return;
      // }

      // // Check total entries for the day
      // final totalEntries = await Supabase.instance.client
      //     .from('height')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate);

      // if (totalEntries.length >= 2) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You can only add 2 entries per day!'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      final dataToInsert = {
        'user_id': userId,
        'value': value.round(),
        'entry_date': formattedDate,
        'time_of_day': timeOfDay, // Add time of day
      };

      await Supabase.instance.client
          .from('height')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('height ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadHeightEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error adding heart rate: $e");
    }
  }

  Future<void> _loadHeightEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('height')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: true)
          .order('time_of_day', ascending: true); // Morning first, then evening

      final List<HealthMetricEntry> fetched =
          (response as List)
              .map(
                (entry) => HealthMetricEntry(
                  id: entry['id'].toString(),
                  value: (entry['value'] as num).toDouble(),
                  date: entry['entry_date'],
                  timestamp:
                      entry['created_at'] != null
                          ? DateTime.parse(
                            entry['created_at'],
                          ).millisecondsSinceEpoch
                          : null,
                  timeOfDay: entry['time_of_day'], // Include time of day
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          heightEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
    }
  }

  Future<void> _addCBCEntry(
    double wbc,
    double rbc,
    // double hemoglobin,
    // double platelets,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Check if entry already exists for this date and time of day
      // final existingEntries = await Supabase.instance.client
      //     .from('cbc_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate)
      //     .eq('time_of_day', timeOfDay);

      // if (existingEntries.isNotEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         'You already have a $timeOfDay CBC entry for this date!',
      //       ),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      //   return;
      // }

      // // Check total entries for the day
      // final totalEntries = await Supabase.instance.client
      //     .from('cbc_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate);

      // if (totalEntries.length >= 2) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You can only add 2 CBC entries per day!'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      final dataToInsert = {
        'user_id': userId,
        'wbc': wbc,
        'rbc': rbc,
        // 'hemoglobin': hemoglobin,
        // 'platelets': platelets,
        'entry_date': formattedDate,
        'time_of_day': timeOfDay,
      };

      await Supabase.instance.client
          .from('cbc_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CBC entry ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadCBCEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error adding CBC entry: $e");
    }
  }

  Future<void> _loadCBCEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('cbc_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .order('time_of_day', ascending: true);

      final List<CBCEntry> fetched =
          (response as List)
              .map(
                (entry) => CBCEntry(
                  id: entry['id'].toString(),
                  wbc: (entry['wbc'] as num).toDouble(),
                  rbc: (entry['rbc'] as num).toDouble(),
                  // Use null-aware operators and provide default values
                  hemoglobin:
                      entry['hemoglobin'] != null
                          ? (entry['hemoglobin'] as num).toDouble()
                          : 0.0, // Default value
                  platelets:
                      entry['platelets'] != null
                          ? (entry['platelets'] as num).toDouble()
                          : 0.0, // Default value
                  date: entry['entry_date'],
                  timestamp:
                      entry['created_at'] != null
                          ? DateTime.parse(
                            entry['created_at'],
                          ).millisecondsSinceEpoch
                          : DateTime.now().millisecondsSinceEpoch,
                  timeOfDay: entry['time_of_day'], // Add this if needed
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          cbcEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading CBC entries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Data Load Failed: $_errorMessage',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchEntries, // Retry button
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // After loading, pass the fetched data and callbacks to children
    final List<Widget> screens = [
      // 1. HomeScreen gets the data lists and the callback functions
      HomeScreen(
        // sugarEntries: _sugarEntries, // PASSING DATA
        // bpEntries: _bpEntries,       // PASSING DATA
        // notes: _notes,
        // onSugarAdded: _addSugarEntry, // PASSING CALLBACK
        // onBPAdded: _addBPEntry,       // PASSING CALLBACK
        // onNoteAdded: _addNoteEntry,
      ),

      // 2. GraphScreen only needs the current fetched data lists
      GraphScreen(
        // sugarEntries: _sugarEntries, // PASSING DYNAMIC DATA
        // bpEntries: _bpEntries,
        // sugarData: _sugarEntries,
        // bpData: _bpEntries,
        // notes: _notes,
        // PASSING DYNAMIC DATA
      ),

      // Placeholder for other screens
      const Center(child: Text('Notes Screen Placeholder')),
      const Center(child: Text('Profile Screen Placeholder')),
    ];

    // return Scaffold(
    //   body: screens[_currentIndex],
    //   bottomNavigationBar: Container(
    //     decoration: BoxDecoration(
    //       boxShadow: [
    //         BoxShadow(
    //           color: Colors.grey.withOpacity(0.2),
    //           blurRadius: 10,
    //           offset: const Offset(0, -2),
    //         ),
    //       ],
    //     ),
    //     child: BottomNavigationBar(
    //       currentIndex: _currentIndex,
    //       onTap: (index) {
    //         setState(() {
    //           _currentIndex = index;
    //         });
    //       },
    //       selectedItemColor: Colors.green[600],
    //       unselectedItemColor: Colors.grey[400],
    //       selectedFontSize: 12,
    //       unselectedFontSize: 12,
    //       type: BottomNavigationBarType.fixed,
    //       items: const [
    //         BottomNavigationBarItem(
    //           icon: Icon(Icons.home_outlined),
    //           activeIcon: Icon(Icons.home),
    //           label: 'Home',
    //         ),
    //         BottomNavigationBarItem(
    //           icon: Icon(Icons.show_chart),
    //           activeIcon: Icon(Icons.show_chart),
    //           label: 'Graph',
    //         ),
    //         // BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
    //         // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    //       ],
    //     ),
    //   ),
    // );
    return Scaffold(
      body: screens[_currentIndex],

      // ------------------------------------------------------
      //  Stylish Floating MIC Button (Glow + Gradient)
      // ------------------------------------------------------
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => VoiceInputScreen(
                    onSugarDetected: (value) async {
                      await _addSugarEntry(
                        value,
                        DateTime.now(),
                        'morning',
                        'pre-meal',
                      );
                    },
                    onBPDetected: (sys, dias) async {
                      await _addBPEntry(sys, dias, DateTime.now(), 'morning');
                    },
                    onHeartRateDetected: (value) async {
                      await _addHeartRateEntry(
                        value,
                        DateTime.now(),
                        'morning',
                      );
                    },
                    onPulseDetected: (value) async {
                      await _addPulseEntry(value, DateTime.now(), 'morning');
                    },
                    onTemperatureDetected: (value) async {
                      await _addTempratureEntry(
                        value,
                        DateTime.now(),
                        'morning',
                      );
                    },
                    onWeightDetected: (value) async {
                      await _addWeightEntry(value, DateTime.now(), 'morning');
                    },
                    onHeightDetected: (value) async {
                      await _addHeightEntry(value, DateTime.now(), 'morning');
                    },
                  ),
            ),
          );
        },
        // onTap: () {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder:
        //           (_) => VoiceInputScreen(
        //             onSugarDetected: (value) {
        //               _addSugarEntry(value, DateTime.now());
        //             },
        //             onBPDetected: (sys, dia) {
        //               _addBPEntry(sys, dia, DateTime.now());
        //             },
        //           ),
        //     ),
        //   );
        // },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 78,
          width: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
                Colors.green.shade900,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 22,
                spreadRadius: 3,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.mic_rounded, color: Colors.white, size: 38),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ------------------------------------------------------
      //  Stylish Bottom Navigation Bar (Glass + Rounded Corners)
      // ------------------------------------------------------
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BottomAppBar(
            color: Colors.white.withOpacity(0.2),
            elevation: 0,
            shape: CircularNotchedRectangle(),
            notchMargin: 10,
            child: Container(
              height: 80,
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _currentIndex,
                selectedFontSize: 14,
                unselectedFontSize: 12,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },

                selectedItemColor: Colors.green.shade700,
                unselectedItemColor: Colors.grey.shade500,
                type: BottomNavigationBarType.fixed,

                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_graph_rounded),
                    label: "Graph",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VoiceInputScreen extends StatefulWidget {
  final Function(double) onSugarDetected;
  final Function(double, double) onBPDetected;
  final Function(double) onHeartRateDetected; // NEW
  final Function(double) onPulseDetected; // NEW
  final Function(double) onTemperatureDetected; // NEW
  final Function(double) onWeightDetected; // NEW
  final Function(double) onHeightDetected;
  // final Function(double) onWBCDetected;
  // final Function(double) onRBCDetected;
  // NEW

  VoiceInputScreen({
    required this.onSugarDetected,
    required this.onBPDetected,
    required this.onHeartRateDetected,
    required this.onPulseDetected,
    required this.onTemperatureDetected,
    required this.onWeightDetected,
    required this.onHeightDetected,
  });

  @override
  _VoiceInputScreenState createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  late stt.SpeechToText _speech;
  bool _listening = false;
  bool _timeout = false;
  String _recognized = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startListening();
  }

  void _startListening() async {
    setState(() {
      _recognized = "";
      _timeout = false;
    });

    bool available = await _speech.initialize();

    if (!available) return;

    setState(() => _listening = true);

    // ---- HARD 3 SEC GLOBAL TIMEOUT ----
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 8), () {
      _speech.stop();
      setState(() {
        _listening = false;
        _timeout = true; // SHOW TRY AGAIN
      });
    });

    _speech.listen(
      onResult: (result) {
        String spoken = result.recognizedWords.trim();
        if (spoken.isEmpty) return;

        setState(() {
          _recognized = spoken;
        });

        // Wait until user COMPLETES sentence
        if (result.finalResult) {
          _processVoice(spoken);
        }
      },
    );
  }

  void showConfirmationBottomSheet({
    required String type,
    required String detectedText,
    required String mainValue,
    required Function(String) onConfirm,
  }) {
    TextEditingController controller = TextEditingController(text: mainValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// DRAG HANDLE
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(height: 20),

                    /// HEADER ROW
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[400]!, Colors.green[600]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            type == "Sugar" || type == "Blood Sugar"
                                ? Icons.water_drop
                                : Icons.monitor_heart,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          "Confirm $type",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 22),

                    /// YOU SAID BOX
                    Container(
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.record_voice_over,
                            color: Colors.green[600],
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              detectedText,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 22),

                    /// VALUE FIELD
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Edit value",
                        prefixIcon: Icon(Icons.edit, color: Colors.green[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    SizedBox(height: 28),

                    /// BUTTONS
                    Row(
                      children: [
                        /// RETRY BUTTON
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                _startListening();
                              },
                              child: Text(
                                "Retry",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),

                        /// SAVE BUTTON
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[400]!,
                                  Colors.green[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onConfirm(controller.text);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addCBCEntry(
    double wbc,
    double rbc,
    // double hemoglobin,
    // double platelets,
    DateTime date,
    String timeOfDay,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Check if entry already exists for this date and time of day
      // final existingEntries = await Supabase.instance.client
      //     .from('cbc_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate)
      //     .eq('time_of_day', timeOfDay);

      // if (existingEntries.isNotEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         'You already have a $timeOfDay CBC entry for this date!',
      //       ),
      //       backgroundColor: Colors.orange,
      //     ),
      //   );
      //   return;
      // }

      // // Check total entries for the day
      // final totalEntries = await Supabase.instance.client
      //     .from('cbc_entries')
      //     .select()
      //     .eq('user_id', userId)
      //     .eq('entry_date', formattedDate);

      // if (totalEntries.length >= 2) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('You can only add 2 CBC entries per day!'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      final dataToInsert = {
        'user_id': userId,
        'wbc': wbc,
        'rbc': rbc,
        // 'hemoglobin': hemoglobin,
        // 'platelets': platelets,
        'entry_date': formattedDate,
        'time_of_day': timeOfDay,
      };

      await Supabase.instance.client
          .from('cbc_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CBC entry ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // await _loadCBCEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error adding CBC entry: $e");
    }
  }

  void showCBCVoiceDetectedSheet(
    BuildContext context,
    double detectedWBC,
    double detectedRBC,
    Function(double wbc, double rbc, DateTime date, String timeOfDay) onConfirm,
  ) {
    final wbcController = TextEditingController(text: detectedWBC.toString());
    final rbcController = TextEditingController(text: detectedRBC.toString());

    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TOP BAR
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurpleAccent,
                                    Colors.deepPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.bloodtype,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Confirm CBC Values',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ---- DATE PICKER ----
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2018),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() => selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.deepPurpleAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ---- Morning / Evening ----
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Morning
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(
                                      () => selectedTimeOfDay = 'morning',
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selectedTimeOfDay == 'morning'
                                              ? Colors.white
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow:
                                          selectedTimeOfDay == 'morning'
                                              ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                              : [],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.wb_sunny,
                                          color:
                                              selectedTimeOfDay == 'morning'
                                                  ? Colors.orange[600]
                                                  : Colors.grey[500],
                                        ),
                                        const SizedBox(width: 8),
                                        const Text("Morning"),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Evening
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(
                                      () => selectedTimeOfDay = 'evening',
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selectedTimeOfDay == 'evening'
                                              ? Colors.white
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow:
                                          selectedTimeOfDay == 'evening'
                                              ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ]
                                              : [],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.nights_stay,
                                          color:
                                              selectedTimeOfDay == 'evening'
                                                  ? Colors.indigo[600]
                                                  : Colors.grey[500],
                                        ),
                                        const SizedBox(width: 8),
                                        const Text("Evening"),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ---- WBC FIELD ----
                        _buildCBCField("WBC Count", "cells/µL", wbcController),
                        const SizedBox(height: 12),

                        // ---- RBC FIELD ----
                        _buildCBCField("RBC Count", "M/µL", rbcController),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: Colors.deepPurpleAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  onConfirm(
                                    double.parse(wbcController.text),
                                    double.parse(rbcController.text),
                                    selectedDate,
                                    selectedTimeOfDay,
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Add Entry",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildCBCField(String title, String unit, TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: title,
        suffixText: unit,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // void _processVoice(String text) {
  //   String lower = text.toLowerCase();

  //   List<String> nums =
  //       RegExp(r'\d+').allMatches(lower).map((e) => e.group(0)!).toList();

  //   // ---------- SUGAR ----------
  //   if (lower.contains("sugar") ||
  //       lower.contains("blood sugar") ||
  //       lower.contains("glucose")) {
  //     if (nums.isNotEmpty) {
  //       double sugar = double.parse(nums.first);

  //       showConfirmationBottomSheet(
  //         type: "Blood Sugar",
  //         detectedText: text,
  //         mainValue: sugar.toString(),
  //         onConfirm: (editedValue) {
  //           widget.onSugarDetected(double.parse(editedValue));
  //         },
  //       );

  //       return;
  //     }
  //   }

  //   // ---------- BP ----------
  //   if (lower.contains("bp") ||
  //       lower.contains("pressure") ||
  //       lower.contains("blood pressure")) {
  //     if (nums.length >= 2) {
  //       double sys = double.parse(nums[0]);
  //       double dias = double.parse(nums[1]);

  //       showConfirmationBottomSheet(
  //         type: "Blood Pressure",
  //         detectedText: text,
  //         mainValue: "$sys/$dias",
  //         onConfirm: (edited) {
  //           final parts = edited.split("/");
  //           widget.onBPDetected(double.parse(parts[0]), double.parse(parts[1]));
  //         },
  //       );
  //       return;
  //     }

  //     // Only one number → assume diastolic default 100
  //     if (nums.length == 1) {
  //       double sys = double.parse(nums[0]);
  //       double dias = 100;

  //       showConfirmationBottomSheet(
  //         type: "Blood Pressure",
  //         detectedText: text,
  //         mainValue: "$sys/$dias",
  //         onConfirm: (edited) {
  //           final parts = edited.split("/");
  //           widget.onBPDetected(double.parse(parts[0]), double.parse(parts[1]));
  //         },
  //       );
  //       return;
  //     }
  //   }
  // }
  // VoiceInputScreen mein _processVoice function ko update karo:

  void _processVoice(String text) {
    String lower = text.toLowerCase();

    List<String> nums =
        RegExp(r'\d+').allMatches(lower).map((e) => e.group(0)!).toList();

    // ---------- HEART RATE ----------
    if (lower.contains("heart") ||
        lower.contains("heart rate") ||
        lower.contains("heartbeat")) {
      if (nums.isNotEmpty) {
        double heartRate = double.parse(nums.first);
        showConfirmationBottomSheet(
          type: "Heart Rate",
          detectedText: text,
          mainValue: heartRate.toString(),
          onConfirm: (editedValue) {
            widget.onHeartRateDetected(double.parse(editedValue));
          },
        );
        return;
      }
    }

    // ---------- PULSE ----------
    if (lower.contains("pulse") || lower.contains("pulse rate")) {
      if (nums.isNotEmpty) {
        double pulse = double.parse(nums.first);
        showConfirmationBottomSheet(
          type: "Pulse",
          detectedText: text,
          mainValue: pulse.toString(),
          onConfirm: (editedValue) {
            widget.onPulseDetected(double.parse(editedValue));
          },
        );
        return;
      }
    }

    // ---------- TEMPERATURE ----------
    if (lower.contains("temperature") ||
        lower.contains("temp") ||
        lower.contains("fever")) {
      if (nums.isNotEmpty) {
        double temp = double.parse(nums.first);
        showConfirmationBottomSheet(
          type: "Temperature",
          detectedText: text,
          mainValue: temp.toString(),
          onConfirm: (editedValue) {
            widget.onTemperatureDetected(double.parse(editedValue));
          },
        );
        return;
      }
    }

    // ---------- WEIGHT ----------
    if (lower.contains("weight")) {
      if (nums.isNotEmpty) {
        double weight = double.parse(nums.first);
        showConfirmationBottomSheet(
          type: "Weight",
          detectedText: text,
          mainValue: weight.toString(),
          onConfirm: (editedValue) {
            widget.onWeightDetected(double.parse(editedValue));
          },
        );
        return;
      }
    }

    // ---------- HEIGHT ----------
    if (lower.contains("height")) {
      if (nums.isNotEmpty) {
        double height = double.parse(nums.first);
        showConfirmationBottomSheet(
          type: "Height",
          detectedText: text,
          mainValue: height.toString(),
          onConfirm: (editedValue) {
            widget.onHeightDetected(double.parse(editedValue));
          },
        );
        return;
      }
    }
    // ---------- CBC WBC / RBC ----------
    if (lower.contains("cbc") ||
        lower.contains("wbc") ||
        lower.contains("white blood cell") ||
        lower.contains("white cells")) {
      if (nums.isNotEmpty) {
        // WBC = पहली number
        double detectedWBC = double.parse(nums[0]);

        // RBC = दूसरी number if available, वरना 0
        double detectedRBC = nums.length > 1 ? double.parse(nums[1]) : 0.0;

        showCBCVoiceDetectedSheet(context, detectedWBC, detectedRBC, (
          wbc,
          rbc,
          date,
          timeOfDay,
        ) {
          _addCBCEntry(wbc, rbc, date, timeOfDay);
        });

        return;
      }
    }

    // ---------- RBC ----------
    // if (lower.contains("rbc") ||
    //     lower.contains("red blood cell") ||
    //     lower.contains("red cells")) {

    //   if (nums.isNotEmpty) {
    //     double rbc = double.parse(nums.first);

    //     showConfirmationBottomSheet(
    //       type: "RBC",
    //       detectedText: text,
    //       mainValue: rbc.toString(),
    //       onConfirm: (editedValue) {
    //         widget.onRBCDetected(double.parse(editedValue));
    //       },
    //     );
    //     return;
    //   }
    // }

    // ---------- SUGAR (already hai) ----------
    if (lower.contains("sugar") ||
        lower.contains("blood sugar") ||
        lower.contains("glucose")) {
      if (nums.isNotEmpty) {
        double sugar = double.parse(nums.first);
        showConfirmationBottomSheet(
          type: "Blood Sugar",
          detectedText: text,
          mainValue: sugar.toString(),
          onConfirm: (editedValue) {
            widget.onSugarDetected(double.parse(editedValue));
          },
        );
        return;
      }
    }

    // ---------- BP (already hai) ----------

    //   // ---------- BP ----------
    if (lower.contains("bp") ||
        lower.contains("pressure") ||
        lower.contains("blood pressure")) {
      if (nums.length >= 2) {
        double sys = double.parse(nums[0]);
        double dias = double.parse(nums[1]);

        showConfirmationBottomSheet(
          type: "Blood Pressure",
          detectedText: text,
          mainValue: "$sys/$dias",
          onConfirm: (edited) {
            final parts = edited.split("/");
            widget.onBPDetected(double.parse(parts[0]), double.parse(parts[1]));
          },
        );
        return;
      }

      // Only one number → assume diastolic default 100
      if (nums.length == 1) {
        double sys = double.parse(nums[0]);
        double dias = 100;

        showConfirmationBottomSheet(
          type: "Blood Pressure",
          detectedText: text,
          mainValue: "$sys/$dias",
          onConfirm: (edited) {
            final parts = edited.split("/");
            widget.onBPDetected(double.parse(parts[0]), double.parse(parts[1]));
          },
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _listening ? Icons.mic : Icons.mic_none,
              size: 120,
              color: Colors.green,
            ),
            SizedBox(height: 20),

            Text(
              _timeout
                  ? "No voice detected"
                  : _listening
                  ? "Listening..."
                  : "Press again",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Text(
              _recognized,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),

            SizedBox(height: 40),

            if (_timeout)
              ElevatedButton(
                onPressed: _startListening,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Press Again",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
