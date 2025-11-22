import 'package:flutter/material.dart';
import 'package:health_care/Graph/GraphScreen.dart';
import 'package:health_care/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllNotes = false; // Yeh line class ke top par add karo
  List<HealthEntry> sugarEntries = [];
  List<HealthMetricEntry> HeartRateEntries = [];
  List<HealthMetricEntry> TempratureEntries = [];
  List<HealthMetricEntry> WeightEntries = [];
  List<HealthMetricEntry> heightEntries = [];
  List<CBCEntry> cbcEntries = [];
  List<HealthMetricEntry> wbcEntries = [];
  List<HealthMetricEntry> pulseEntries = [];
  List<BPEntry> bpEntries = [];
  List<NoteEntry> notes = [];
  bool _isLoading = true;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _listeningField = ''; // Track which field is listening

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _loadAllData();
  }

  final controller = TextEditingController();
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadSugarEntries(), _loadBPEntries(), _loadNotes()]);
    setState(() => _isLoading = false);
  }

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

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('note_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false); // Latest pehle

      setState(() {
        notes =
            (response as List)
                .map(
                  (entry) => NoteEntry(
                    id: entry['id'].toString(),
                    text: entry['text'],
                    date: entry['entry_date'],
                    timestamp:
                        entry['created_at'] != null
                            ? DateTime.parse(
                              entry['created_at'],
                            ).millisecondsSinceEpoch
                            : DateTime.now().millisecondsSinceEpoch,
                  ),
                )
                .toList();

        // IMPORTANT: List ko reverse mat karo, already sorted hai!
      });
    } catch (e) {
      print('Error loading notes: $e');
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

  Future<void> _addWBCEntry(
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

      final existingEntries = await Supabase.instance.client
          .from('wbc_counts')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', formattedDate)
          .eq('time_of_day', timeOfDay);

      if (existingEntries.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You already have a $timeOfDay entry for this date!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check total entries for the day
      final totalEntries = await Supabase.instance.client
          .from('wbc_counts')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', formattedDate);

      if (totalEntries.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only add 2 entries per day!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final dataToInsert = {
        'user_id': userId,
        'value': value.round(),
        'entry_date': formattedDate,
        'time_of_day': timeOfDay, // Add time of day
      };

      await Supabase.instance.client
          .from('wbc_counts')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('wbc_counts ($timeOfDay) added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadWBCEntries();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error adding heart rate: $e");
    }
  }

  Future<void> _loadWBCEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('wbc_counts')
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
          wbcEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
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

  Future<void> _addNote(String text, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first!')));
        return;
      }

      final dataToInsert = {
        'user_id': userId,
        'text': text,
        'entry_date': DateFormat('yyyy-MM-dd').format(date),
      };

      await Supabase.instance.client
          .from('note_entries')
          .insert(dataToInsert)
          .select();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved successfully!')));

      await _loadNotes();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _startListening1(TextEditingController controller) async {
    bool available = await _speech.initialize();
    if (available) {
      _isListening = true;

      await _speech.listen(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        onResult: (val) {
          controller.text = val.recognizedWords;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        },
        pauseFor: Duration(seconds: 10),
        listenFor: Duration(minutes: 10),
      );
    }
  }

  // Voice Input Helper Method
  Future<void> _startListening(
    TextEditingController controller,
    StateSetter setModalState,
    String fieldId,
  ) async {
    bool available = await _speech.initialize();
    if (available) {
      setModalState(() {
        _isListening = true;
        _listeningField = fieldId;
      });
      _speech.listen(
        onResult: (result) {
          setModalState(() {
            // Extract only numbers from recognized text
            String recognizedText = result.recognizedWords;
            String numbersOnly = recognizedText.replaceAll(
              RegExp(r'[^0-9.]'),
              '',
            );
            controller.text = numbersOnly;
          });
        },
        listenFor: Duration(seconds: 5),
      );
    }
  }

  void _stopListening1() {
    _speech.stop();
    _isListening = false;
  }

  void _stopListening(StateSetter setModalState) {
    _speech.stop();
    setModalState(() {
      _isListening = false;
      _listeningField = '';
    });
  }

  // Pulse Dialog with Morning/Evening Selection
  void showPulseDialog(BuildContext context) {
    final pulseController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Default to morning

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                                      Colors.purple[400]!,
                                      Colors.purple[600]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Add Pulse Rate',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.purple[600]!,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                    color: Colors.purple[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
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

                          // Morning/Evening Selection

                          // Pulse Rate Input
                          TextField(
                            controller: pulseController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter pulse rate',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              suffixText: 'bpm',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningField == 'pulse'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color:
                                      _isListening && _listeningField == 'pulse'
                                          ? Colors.red
                                          : Colors.purple[600],
                                ),
                                onPressed: () {
                                  if (_isListening &&
                                      _listeningField == 'pulse') {
                                    _stopListening(setModalState);
                                  } else {
                                    _startListening(
                                      pulseController,
                                      setModalState,
                                      'pulse',
                                    );
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.purple[400]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple[400]!,
                                        Colors.purple[600]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (pulseController.text.isNotEmpty) {
                                        await _addPulseEntry(
                                          double.parse(pulseController.text),
                                          selectedDate,
                                          selectedTimeOfDay,
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter pulse rate',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Entry',
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
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void showWeightDialog(BuildContext context) {
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Default to morning

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                                    colors: [Colors.tealAccent, Colors.teal],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Add Pulse Rate',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.teal,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                    color: Colors.teal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
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

                          // Morning/Evening Selection

                          // Pulse Rate Input
                          TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter Your Weight',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              suffixText: 'bpm',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningField == 'weight'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color:
                                      _isListening &&
                                              _listeningField == 'weight'
                                          ? Colors.red
                                          : Colors.purple[600],
                                ),
                                onPressed: () {
                                  if (_isListening &&
                                      _listeningField == 'weight') {
                                    _stopListening(setModalState);
                                  } else {
                                    _startListening(
                                      weightController,
                                      setModalState,
                                      'weight',
                                    );
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.tealAccent, Colors.teal],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (weightController.text.isNotEmpty) {
                                        await _addWeightEntry(
                                          double.parse(weightController.text),
                                          selectedDate,
                                          selectedTimeOfDay,
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter pulse rate',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Entry',
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
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void showHeightDialog(BuildContext context) {
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Default to morning

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                                      Colors.indigoAccent,
                                      Colors.indigo,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Add Your height',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.indigoAccent,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                    color: Colors.indigoAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
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

                          // Morning/Evening Selection
                          // Pulse Rate Input
                          TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter Your Height',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              suffixText: 'inches',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningField == 'Height'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color:
                                      _isListening &&
                                              _listeningField == 'Height'
                                          ? Colors.red
                                          : Colors.purple[600],
                                ),
                                onPressed: () {
                                  if (_isListening &&
                                      _listeningField == 'Height') {
                                    _stopListening(setModalState);
                                  } else {
                                    _startListening(
                                      weightController,
                                      setModalState,
                                      'Height',
                                    );
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.tealAccent, Colors.teal],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (weightController.text.isNotEmpty) {
                                        await _addHeightEntry(
                                          double.parse(weightController.text),
                                          selectedDate,
                                          selectedTimeOfDay,
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter Height',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Entry',
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
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void showCBCDialog(BuildContext context) {
    final wbcController = TextEditingController();
    final rbcController = TextEditingController();
    // Remove hemoglobin and platelets controllers since we're not using them
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                                'Add CBC Test',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.deepPurpleAccent,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
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

                          // Morning/Evening Selection
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
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
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Morning',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedTimeOfDay == 'morning'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                                            Icons.nights_stay,
                                            color:
                                                selectedTimeOfDay == 'evening'
                                                    ? Colors.indigo[600]
                                                    : Colors.grey[500],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Evening',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedTimeOfDay == 'evening'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
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
                          const SizedBox(height: 16),

                          // Only 2 CBC Input Fields
                          _buildCBCTextField(
                            wbcController,
                            'WBC Count',
                            'cells/μL',
                            'Normal: 4,000-11,000',
                            setModalState,
                            'wbc',
                          ),
                          const SizedBox(height: 12),
                          _buildCBCTextField(
                            rbcController,
                            'RBC Count',
                            'M/μL',
                            'Normal: 4.0-5.5',
                            setModalState,
                            'rbc',
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurpleAccent,
                                        Colors.deepPurple,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // FIXED: Only check WBC and RBC controllers
                                      if (wbcController.text.isNotEmpty &&
                                          rbcController.text.isNotEmpty) {
                                        await _addCBCEntry(
                                          double.parse(wbcController.text),
                                          double.parse(rbcController.text),
                                          selectedDate,
                                          selectedTimeOfDay,
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill all CBC values',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Entry',
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
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  // Helper widget for CBC text fields
  Widget _buildCBCTextField(
    TextEditingController controller,
    String label,
    String unit,
    String hint,
    StateSetter setModalState,
    String fieldId,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
        suffixText: unit,
        suffixStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: IconButton(
          icon: Icon(
            _isListening && _listeningField == fieldId
                ? Icons.mic
                : Icons.mic_none,
            color:
                _isListening && _listeningField == fieldId
                    ? Colors.red
                    : Colors.deepPurple,
          ),
          onPressed: () {
            if (_isListening && _listeningField == fieldId) {
              _stopListening(setModalState);
            } else {
              _startListening(controller, setModalState, fieldId);
            }
          },
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void showWBCDialog(BuildContext context) {
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Default to morning

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                                      Colors.lightBlueAccent,
                                      Colors.lightBlue,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Add Your WBC Count',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.lightBlueAccent,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                    color: Colors.lightBlueAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
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

                          // Morning/Evening Selection
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
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
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Morning',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedTimeOfDay == 'morning'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                                            Icons.nights_stay,
                                            color:
                                                selectedTimeOfDay == 'evening'
                                                    ? Colors.lightBlueAccent
                                                    : Colors.grey[500],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Evening',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedTimeOfDay == 'evening'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
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
                          const SizedBox(height: 16),

                          // Pulse Rate Input
                          TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter Your WBC Count',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              suffixText: 'µL',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningField == 'WBC'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color:
                                      _isListening && _listeningField == 'WBC'
                                          ? Colors.red
                                          : Colors.purple[600],
                                ),
                                onPressed: () {
                                  if (_isListening &&
                                      _listeningField == 'WBC') {
                                    _stopListening(setModalState);
                                  } else {
                                    _startListening(
                                      weightController,
                                      setModalState,
                                      'WBC',
                                    );
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.deepPurpleAccent,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.lightBlueAccent,
                                        Colors.lightBlue,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (weightController.text.isNotEmpty) {
                                        await _addWBCEntry(
                                          double.parse(weightController.text),
                                          selectedDate,
                                          selectedTimeOfDay,
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter WBC Count',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Entry',
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
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  // Add Pulse Entry Function with Validation
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

  void showHeartRateDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Local variable for modal

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                    Colors.pink[400]!,
                                    Colors.pink[600]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Add Heart Rate',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Date Picker
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.pink[600]!,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
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
                                  color: Colors.pink[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(selectedDate),
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

                        // Morning/Evening Selection

                        // Heart Rate Input
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter Heart Rate',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            suffixText: 'bpm',
                            suffixStyle: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: IconButton(
                              icon: Icon(
                                _isListening && _listeningField == 'heart rate'
                                    ? Icons.mic
                                    : Icons.mic_none,
                                color:
                                    _isListening &&
                                            _listeningField == 'heart rate'
                                        ? Colors.red
                                        : Colors.pink[600],
                              ),
                              onPressed: () {
                                if (_isListening &&
                                    _listeningField == 'heart rate') {
                                  _stopListening(setModalState);
                                } else {
                                  _startListening(
                                    controller,
                                    setModalState,
                                    'heart rate',
                                  );
                                }
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.pink[400]!,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.pink[400]!,
                                      Colors.pink[600]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (controller.text.isNotEmpty) {
                                      await _addHeartRateEntry(
                                        double.parse(controller.text),
                                        selectedDate,
                                        selectedTimeOfDay, // Pass time of day
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter heart rate value',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Entry',
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
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void showTemperatureDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Local variable for modal

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                  colors: [Colors.blueAccent, Colors.blue],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Add Body Temperature',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Date Picker
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.pink[600]!,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
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
                                  color: Colors.pink[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(selectedDate),
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

                        // Morning/Evening Selection

                        // Heart Rate Input
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter Body Temperature',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            suffixText: '°C',
                            suffixStyle: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: IconButton(
                              icon: Icon(
                                _isListening && _listeningField == 'Temprature'
                                    ? Icons.mic
                                    : Icons.mic_none,
                                color:
                                    _isListening &&
                                            _listeningField == 'Temprature'
                                        ? Colors.red
                                        : Colors.pink[600],
                              ),
                              onPressed: () {
                                if (_isListening &&
                                    _listeningField == 'Temprature') {
                                  _stopListening(setModalState);
                                } else {
                                  _startListening(
                                    controller,
                                    setModalState,
                                    'Temprature',
                                  );
                                }
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.pink[400]!,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.pink[400]!,
                                      Colors.pink[600]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (controller.text.isNotEmpty) {
                                      await _addTempratureEntry(
                                        double.parse(controller.text),
                                        selectedDate,
                                        selectedTimeOfDay, // Pass time of day
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter heart rate value',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Entry',
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
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void showSugarDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Default to morning
    String selectedMealTime = 'pre-meal'; // Default to pre-meal

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                                      Colors.green[400]!,
                                      Colors.green[600]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.water_drop,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Add Blood Sugar',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.green[600]!,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
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

                          // Morning/Evening Selection

                          // Pre-meal/Post-meal Selection
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(
                                        () => selectedMealTime = 'pre-meal',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedMealTime == 'pre-meal'
                                                ? Colors.white
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow:
                                            selectedMealTime == 'pre-meal'
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
                                            Icons.restaurant_menu,
                                            color:
                                                selectedMealTime == 'pre-meal'
                                                    ? Colors.blue[600]
                                                    : Colors.grey[500],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pre-meal',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedMealTime == 'pre-meal'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(
                                        () => selectedMealTime = 'post-meal',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedMealTime == 'post-meal'
                                                ? Colors.white
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow:
                                            selectedMealTime == 'post-meal'
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
                                            Icons.fastfood,
                                            color:
                                                selectedMealTime == 'post-meal'
                                                    ? Colors.purple[600]
                                                    : Colors.grey[500],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Post-meal',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedMealTime ==
                                                          'post-meal'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
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
                          const SizedBox(height: 16),

                          // Blood Sugar Input
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter glucose level',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              suffixText: 'mg/dL',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningField == 'sugar'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color:
                                      _isListening && _listeningField == 'sugar'
                                          ? Colors.red
                                          : Colors.green[600],
                                ),
                                onPressed: () {
                                  if (_isListening &&
                                      _listeningField == 'sugar') {
                                    _stopListening(setModalState);
                                  } else {
                                    _startListening(
                                      controller,
                                      setModalState,
                                      'sugar',
                                    );
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.green[400]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (controller.text.isNotEmpty) {
                                        await _addSugarEntry(
                                          double.parse(controller.text),
                                          selectedDate,
                                          selectedTimeOfDay,
                                          selectedMealTime, // Pass meal time
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter glucose level',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Entry',
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
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void showBPDialog(BuildContext context) {
    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedTimeOfDay = 'morning'; // Default to morning

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
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
                                      Colors.red[300]!,
                                      Colors.red[500]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Add Blood Pressure',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.red[500]!,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                    color: Colors.red[500],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
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

                          // Morning/Evening Selection
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
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
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Morning',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedTimeOfDay == 'morning'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                                            Icons.nights_stay,
                                            color:
                                                selectedTimeOfDay == 'evening'
                                                    ? Colors.indigo[600]
                                                    : Colors.grey[500],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Evening',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  selectedTimeOfDay == 'evening'
                                                      ? Colors.black87
                                                      : Colors.grey[600],
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
                          const SizedBox(height: 16),

                          // Systolic Input
                          TextField(
                            controller: systolicController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Systolic (Upper)',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              suffixText: 'mmHg',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningField == 'systolic'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color:
                                      _isListening &&
                                              _listeningField == 'systolic'
                                          ? Colors.red
                                          : Colors.red[600],
                                ),
                                onPressed: () {
                                  if (_isListening &&
                                      _listeningField == 'systolic') {
                                    _stopListening(setModalState);
                                  } else {
                                    _startListening(
                                      systolicController,
                                      setModalState,
                                      'systolic',
                                    );
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Diastolic Input
                          TextField(
                            controller: diastolicController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Diastolic (Lower)',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              suffixText: 'mmHg',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningField == 'diastolic'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color:
                                      _isListening &&
                                              _listeningField == 'diastolic'
                                          ? Colors.red
                                          : Colors.red[600],
                                ),
                                onPressed: () {
                                  if (_isListening &&
                                      _listeningField == 'diastolic') {
                                    _stopListening(setModalState);
                                  } else {
                                    _startListening(
                                      diastolicController,
                                      setModalState,
                                      'diastolic',
                                    );
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.red[400]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red[400]!,
                                        Colors.red[600]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (systolicController.text.isNotEmpty &&
                                          diastolicController.text.isNotEmpty) {
                                        await _addBPEntry(
                                          double.parse(systolicController.text),
                                          double.parse(
                                            diastolicController.text,
                                          ),
                                          selectedDate,
                                          selectedTimeOfDay, // Pass time of day
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill all fields',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Entry',
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
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void showNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                    Colors.blue[300]!,
                                    Colors.blue[500]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Add Note',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.blue[500]!,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
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
                                  color: Colors.blue[500],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(selectedDate),
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
                        // showNoteDialog (approx line 1030)

                        // ... (code above)

                        // TextField(
                        //   controller: controller, // <-- Local controller
                        //   maxLines: 5,
                        //   style: const TextStyle(fontSize: 16),
                        //   decoration: InputDecoration(
                        //     hintText: 'Write your health note here...',
                        //     hintStyle: TextStyle(color: Colors.grey[400]),
                        //     // MIC ICON FOR NOTES
                        //     suffixIcon: Padding(
                        //       padding: const EdgeInsets.only(right: 8, top: 8),
                        //       child: Align(
                        //         alignment: Alignment.topRight,
                        //         child: IconButton(
                        //           icon: Icon(
                        //             _isListening && _listeningField == 'note'
                        //                 ? Icons.mic
                        //                 : Icons.mic_none,
                        //             color:
                        //                 _isListening &&
                        //                         _listeningField == 'note'
                        //                     ? Colors.red
                        //                     : Colors.blue[600],
                        //           ),
                        //           onPressed: () {
                        //             if (_isListening &&
                        //                 _listeningField == 'note') {
                        //               _stopListening(setModalState);
                        //             } else {
                        //               // CORRECTED CALL
                        //               _startListeningnote(
                        //                 controller, // <--- Pass the local controller
                        //                 setModalState, // <--- Pass the StateSetter
                        //               );
                        //             }
                        //           },
                        //         ),
                        //       ),
                        //     ),
                        //   )
                        // )
                        // TextField(
                        //   controller: controller,
                        //   maxLines: 5,
                        //   style: const TextStyle(fontSize: 16),
                        //   decoration: InputDecoration(
                        //     hintText: 'Write your health note here...',
                        //     hintStyle: TextStyle(color: Colors.grey[400]),
                        //     filled: true,
                        //     fillColor: Colors.grey[50],
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(20),
                        //       borderSide: BorderSide.none,
                        //     ),
                        //     focusedBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(20),
                        //       borderSide: BorderSide(
                        //         color: Colors.blue[400]!,
                        //         width: 2,
                        //       ),
                        //     ),
                        //     contentPadding: const EdgeInsets.all(20),
                        //   ),
                        // ),
                        TextField(
                          controller: controller,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Write your health note here...',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(20),

                            // 👇 MIC BUTTON HERE
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : Colors.blue,
                              ),
                              onPressed: () {
                                if (_isListening) {
                                  _stopListening1();
                                } else {
                                  _startListening1(controller);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[400]!,
                                      Colors.blue[600]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (controller.text.isNotEmpty) {
                                      await _addNote(
                                        controller.text,
                                        selectedDate,
                                      );
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Note',
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
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  double calculateSugarAverage() {
    if (sugarEntries.isEmpty) return 0;
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final currentMonthEntries =
        sugarEntries.where((entry) {
          final entryDate = DateTime.parse(entry.date);
          return entryDate.month == currentMonth &&
              entryDate.year == currentYear;
        }).toList();

    if (currentMonthEntries.isEmpty) return 0;
    final sum = currentMonthEntries.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );
    return sum / currentMonthEntries.length;
  }

  Map<String, double> calculateBPAverage() {
    if (bpEntries.isEmpty) return {'systolic': 0, 'diastolic': 0};
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final currentMonthEntries =
        bpEntries.where((entry) {
          final entryDate = DateTime.parse(entry.date);
          return entryDate.month == currentMonth &&
              entryDate.year == currentYear;
        }).toList();

    if (currentMonthEntries.isEmpty) return {'systolic': 0, 'diastolic': 0};
    final sumSys = currentMonthEntries.fold(
      0.0,
      (sum, entry) => sum + entry.systolic,
    );
    final sumDia = currentMonthEntries.fold(
      0.0,
      (sum, entry) => sum + entry.diastolic,
    );
    return {
      'systolic': sumSys / currentMonthEntries.length,
      'diastolic': sumDia / currentMonthEntries.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actionItems = [
      {
        "title": "Blood Sugar",
        "icon": Icons.water_drop,
        "gradient": [Colors.greenAccent, Colors.green],
        "onTap": () => showSugarDialog(context),
      },
      {
        "title": "Blood Pressure",
        "icon": Icons.favorite,
        "gradient": [Colors.redAccent, Colors.red],
        "onTap": () => showBPDialog(context),
      },
      {
        "title": "Heart Rate",
        "icon": Icons.monitor_heart,
        "gradient": [Colors.pinkAccent, Colors.pink],
        "onTap": () {
          showHeartRateDialog(context);
        },
      },
      {
        "title": "Pulse",
        "icon": Icons.favorite_border,
        "gradient": [Colors.orangeAccent, Colors.deepOrange],
        "onTap": () {
          showPulseDialog(context);
        },
      },
      {
        "title": "Temperature",
        "icon": Icons.thermostat,
        "gradient": [Colors.blueAccent, Colors.blue],
        "onTap": () {
          showTemperatureDialog(context);
        },
      },
      {
        "title": "Weight",
        "icon": Icons.monitor_weight,
        "gradient": [Colors.tealAccent, Colors.teal],
        "onTap": () {
          showWeightDialog(context);
        },
      },
      {
        "title": "Height",
        "icon": Icons.height,
        "gradient": [Colors.indigoAccent, Colors.indigo],
        "onTap": () {
          showHeightDialog(context);
        },
      },
      {
        "title": "CBC",
        "icon": Icons.bloodtype,
        "gradient": [Colors.deepPurpleAccent, Colors.deepPurple],
        "onTap": () {
          showCBCDialog(context);
        },
      },
      // {
      //   "title": "WBC",
      //   "icon": Icons.biotech,
      //   "gradient": [Colors.lightBlueAccent, Colors.lightBlue],
      //   "onTap": () {
      //     showWBCDialog(context);
      //   },
      // },
    ];

    final bpAvg = calculateBPAverage();
    final lastSugar = sugarEntries.isNotEmpty ? sugarEntries.first : null;
    final lastBP = bpEntries.isNotEmpty ? bpEntries.first : null;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[400]!, Colors.green[600]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saarthi',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay healthy, stay happy! 💚',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children:
                            actionItems.map((item) {
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                child: _buildActionCard(
                                  context,
                                  item["title"],
                                  item["icon"],
                                  item["gradient"],
                                  item["onTap"],
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 12),
                              const Text(
                                'Your Statistics',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Sugar Avg',
                                  '${calculateSugarAverage().toStringAsFixed(1)}',
                                  'mg/dL',
                                  Icons.trending_up,
                                  [Colors.green[100]!, Colors.green[50]!],
                                  Colors.green[600]!,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'BP Avg',
                                  '${bpAvg['systolic']!.toInt()}/${bpAvg['diastolic']!.toInt()}',
                                  'mmHg',
                                  Icons.favorite,
                                  [Colors.red[100]!, Colors.red[50]!],
                                  Colors.red[600]!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentEntry(
                      'Blood Sugar',
                      '${lastSugar?.value ?? 0.0} mg/dL',
                      lastSugar?.date ?? "No entries yet",
                      Icons.water_drop,
                      [Colors.green[100]!, Colors.green[50]!],
                      Colors.green[600]!,
                    ),
                    const SizedBox(height: 12),
                    _buildRecentEntry(
                      'Blood Pressure',
                      '${lastBP?.systolic.toInt() ?? 0}/${lastBP?.diastolic.toInt() ?? 0} mmHg',
                      lastBP?.date ?? "No entries yet",
                      Icons.favorite,
                      [Colors.red[100]!, Colors.red[50]!],
                      Colors.red[600]!,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Notes & Observations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => showNoteDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.blue[600],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add a new note',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Track symptoms, meals & more',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue[400],
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // if (notes.isNotEmpty) ...[
                    //   const SizedBox(height: 16),
                    //   ...notes
                    //       .take(3)
                    //       .map(
                    //         (note) => Container(
                    //           margin: const EdgeInsets.only(bottom: 12),
                    //           padding: const EdgeInsets.all(20),
                    //           decoration: BoxDecoration(
                    //             color: Colors.white,
                    //             borderRadius: BorderRadius.circular(20),
                    //             border: Border.all(
                    //               color: Colors.grey[200]!,
                    //               width: 1,
                    //             ),
                    //           ),
                    //           child: Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Row(
                    //                 children: [
                    //                   Container(
                    //                     padding: const EdgeInsets.all(8),
                    //                     decoration: BoxDecoration(
                    //                       color: Colors.amber[50],
                    //                       borderRadius: BorderRadius.circular(
                    //                         10,
                    //                       ),
                    //                     ),
                    //                     child: Icon(
                    //                       Icons.note,
                    //                       color: Colors.amber[700],
                    //                       size: 18,
                    //                     ),
                    //                   ),
                    //                   const SizedBox(width: 12),
                    //                   Expanded(
                    //                     child: Text(
                    //                       note.text,
                    //                       style: const TextStyle(
                    //                         fontSize: 15,
                    //                         fontWeight: FontWeight.w500,
                    //                         height: 1.4,
                    //                       ),
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //               const SizedBox(height: 12),
                    //               Text(
                    //                 DateFormat(
                    //                   'dd MMM yyyy',
                    //                 ).format(DateTime.parse(note.date)),
                    //                 style: TextStyle(
                    //                   fontSize: 12,
                    //                   color: Colors.grey[500],
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    // ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...notes
                          .take(
                            _showAllNotes ? notes.length : 5,
                          ) // Agar _showAllNotes true hai to sare, nahi to 5
                          .map(
                            (note) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[50],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.note,
                                          color: Colors.amber[700],
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          note.text,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(DateTime.parse(note.date)),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                      // View More / View Less button
                      if (notes.length > 5) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _showAllNotes = !_showAllNotes; // Toggle karo
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.amber[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showAllNotes ? 'View Less' : 'View More',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showAllNotes
                                      ? Icons.arrow_upward
                                      : Icons.arrow_forward,
                                  size: 16,
                                  color: Colors.amber[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[1].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: gradientColors[1], size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add entry',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    List<Color> bgColors,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: bgColors),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentEntry(
    String title,
    String value,
    String date,
    IconData icon,
    List<Color> bgColors,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: bgColors),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date == "No entries yet"
                      ? date
                      : DateFormat('dd MMM yyyy').format(DateTime.parse(date)),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:health_care/Graph/GraphScreen.dart';
// import 'package:health_care/profile/profile_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<HealthEntry> sugarEntries = [];
//   List<BPEntry> bpEntries = [];
//   List<NoteEntry> notes = [];
//   bool _isLoading = true;
//   late stt.SpeechToText _speech;
//   bool _isListening = false;

//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//     _loadAllData();
//   }

//   Future<void> _loadAllData() async {
//     setState(() => _isLoading = true);
//     await Future.wait([_loadSugarEntries(), _loadBPEntries(), _loadNotes()]);
//     setState(() => _isLoading = false);
//   }

//   Future<void> _loadSugarEntries() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');
//       if (userId == null) return;

//       final response = await Supabase.instance.client
//           .from('health_entries')
//           .select()
//           .eq('user_id', userId)
//           .order('entry_date', ascending: false);

//       setState(() {
//         sugarEntries = (response as List)
//             .map(
//               (entry) => HealthEntry(
//                 id: entry['id'].toString(),
//                 value: (entry['value'] as num).toDouble(),
//                 date: entry['entry_date'],
//                 timestamp: entry['created_at'] != null
//                     ? DateTime.parse(entry['created_at']).millisecondsSinceEpoch
//                     : DateTime.now().millisecondsSinceEpoch,
//               ),
//             )
//             .toList();
//       });
//     } catch (e) {
//       print('Error loading sugar entries: $e');
//     }
//   }

//   Future<void> _loadBPEntries() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');
//       if (userId == null) return;

//       final response = await Supabase.instance.client
//           .from('bp_entries')
//           .select()
//           .eq('user_id', userId)
//           .order('entry_date', ascending: false);

//       setState(() {
//         bpEntries = (response as List)
//             .map(
//               (entry) => BPEntry(
//                 id: entry['id'].toString(),
//                 systolic: (entry['systolic'] as num).toDouble(),
//                 diastolic: (entry['diastolic'] as num).toDouble(),
//                 date: entry['entry_date'],
//                 timestamp: entry['created_at'] != null
//                     ? DateTime.parse(entry['created_at']).millisecondsSinceEpoch
//                     : DateTime.now().millisecondsSinceEpoch,
//               ),
//             )
//             .toList();
//       });
//     } catch (e) {
//       print('Error loading BP entries: $e');
//     }
//   }

//   Future<void> _loadNotes() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');
//       if (userId == null) return;

//       final response = await Supabase.instance.client
//           .from('note_entries')
//           .select()
//           .eq('user_id', userId)
//           .order('entry_date', ascending: false);

//       setState(() {
//         notes = (response as List)
//             .map(
//               (entry) => NoteEntry(
//                 id: entry['id'].toString(),
//                 text: entry['text'],
//                 date: entry['entry_date'],
//                 timestamp: entry['created_at'] != null
//                     ? DateTime.parse(entry['created_at']).millisecondsSinceEpoch
//                     : DateTime.now().millisecondsSinceEpoch,
//               ),
//             )
//             .toList();
//       });
//     } catch (e) {
//       print('Error loading notes: $e');
//     }
//   }

//   Future<void> _addSugarEntry(double value, DateTime date) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');

//       if (userId == null || userId.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please login first!')));
//         return;
//       }

//       final dataToInsert = {
//         'user_id': userId,
//         'value': value,
//         'entry_date': DateFormat('yyyy-MM-dd').format(date),
//       };

//       await Supabase.instance.client
//           .from('health_entries')
//           .insert(dataToInsert)
//           .select();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Sugar entry added successfully!')),
//       );

//       await _loadSugarEntries();
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _addBPEntry(
//       double systolic, double diastolic, DateTime date) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');

//       if (userId == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please login first!')));
//         return;
//       }

//       final dataToInsert = {
//         'user_id': userId,
//         'systolic': systolic,
//         'diastolic': diastolic,
//         'entry_date': DateFormat('yyyy-MM-dd').format(date),
//       };

//       await Supabase.instance.client
//           .from('bp_entries')
//           .insert(dataToInsert)
//           .select();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('BP entry added successfully!')),
//       );

//       await _loadBPEntries();
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _addNote(String text, DateTime date) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');

//       if (userId == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please login first!')));
//         return;
//       }

//       final dataToInsert = {
//         'user_id': userId,
//         'text': text,
//         'entry_date': DateFormat('yyyy-MM-dd').format(date),
//       };

//       await Supabase.instance.client
//           .from('note_entries')
//           .insert(dataToInsert)
//           .select();

//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Note saved successfully!')));

//       await _loadNotes();
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   // Voice Input Helper Method
//   Future<void> _startListening(
//       TextEditingController controller, StateSetter setModalState) async {
//     bool available = await _speech.initialize();
//     if (available) {
//       setModalState(() => _isListening = true);
//       _speech.listen(
//         onResult: (result) {
//           setModalState(() {
//             // Extract only numbers from recognized text
//             String recognizedText = result.recognizedWords;
//             String numbersOnly = recognizedText.replaceAll(RegExp(r'[^0-9.]'), '');
//             controller.text = numbersOnly;
//           });
//         },
//         listenFor: Duration(seconds: 5),
//       );
//     }
//   }

//   void _stopListening(StateSetter setModalState) {
//     _speech.stop();
//     setModalState(() => _isListening = false);
//   }

//   void showSugarDialog(BuildContext context) {
//     final controller = TextEditingController();
//     DateTime selectedDate = DateTime.now();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//           ),
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 50,
//                   height: 5,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.green[400]!, Colors.green[600]!],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: const Icon(Icons.water_drop,
//                           color: Colors.white, size: 24),
//                     ),
//                     const SizedBox(width: 16),
//                     const Text('Add Blood Sugar',
//                         style: TextStyle(
//                             fontSize: 22, fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 GestureDetector(
//                   onTap: () async {
//                     final date = await showDatePicker(
//                       context: context,
//                       initialDate: selectedDate,
//                       firstDate: DateTime(2020),
//                       lastDate: DateTime.now(),
//                       builder: (context, child) {
//                         return Theme(
//                           data: Theme.of(context).copyWith(
//                             colorScheme: ColorScheme.light(
//                               primary: Colors.green[600]!,
//                               onPrimary: Colors.white,
//                             ),
//                           ),
//                           child: child!,
//                         );
//                       },
//                     );
//                     if (date != null) {
//                       setModalState(() => selectedDate = date);
//                     }
//                   },
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[50],
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.grey[200]!),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.calendar_today,
//                             color: Colors.green[600], size: 20),
//                         const SizedBox(width: 12),
//                         Text(DateFormat('dd MMM yyyy').format(selectedDate),
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.w500)),
//                         const Spacer(),
//                         Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: controller,
//                   keyboardType: TextInputType.number,
//                   style: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.w500),
//                   decoration: InputDecoration(
//                     hintText: 'Enter glucose level',
//                     hintStyle: TextStyle(color: Colors.grey[400]),
//                     suffixText: 'mg/dL',
//                     suffixStyle: TextStyle(
//                         color: Colors.grey[600], fontWeight: FontWeight.w600),
//                     // MIC ICON YAHAN ADD KIYA
//                     prefixIcon: IconButton(
//                       icon: Icon(
//                         _isListening ? Icons.mic : Icons.mic_none,
//                         color: _isListening ? Colors.red : Colors.green[600],
//                       ),
//                       onPressed: () {
//                         if (_isListening) {
//                           _stopListening(setModalState);
//                         } else {
//                           _startListening(controller, setModalState);
//                         }
//                       },
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[50],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide.none,
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide:
//                           BorderSide(color: Colors.green[400]!, width: 2),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 18),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                         child: Text('Cancel',
//                             style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey[700])),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       flex: 2,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.green[400]!, Colors.green[600]!],
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.green.withOpacity(0.3),
//                               blurRadius: 12,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             if (controller.text.isNotEmpty) {
//                               await _addSugarEntry(
//                                   double.parse(controller.text), selectedDate);
//                               Navigator.pop(context);
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                           ),
//                           child: const Text('Add Entry',
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void showBPDialog(BuildContext context) {
//     final systolicController = TextEditingController();
//     final diastolicController = TextEditingController();
//     DateTime selectedDate = DateTime.now();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//           ),
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 50,
//                   height: 5,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.red[300]!, Colors.red[500]!],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: const Icon(Icons.favorite,
//                           color: Colors.white, size: 24),
//                     ),
//                     const SizedBox(width: 16),
//                     const Text('Add Blood Pressure',
//                         style: TextStyle(
//                             fontSize: 22, fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 GestureDetector(
//                   onTap: () async {
//                     final date = await showDatePicker(
//                       context: context,
//                       initialDate: selectedDate,
//                       firstDate: DateTime(2020),
//                       lastDate: DateTime.now(),
//                       builder: (context, child) {
//                         return Theme(
//                           data: Theme.of(context).copyWith(
//                             colorScheme: ColorScheme.light(
//                               primary: Colors.red[500]!,
//                               onPrimary: Colors.white,
//                             ),
//                           ),
//                           child: child!,
//                         );
//                       },
//                     );
//                     if (date != null) {
//                       setModalState(() => selectedDate = date);
//                     }
//                   },
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[50],
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.grey[200]!),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.calendar_today,
//                             color: Colors.red[500], size: 20),
//                         const SizedBox(width: 12),
//                         Text(DateFormat('dd MMM yyyy').format(selectedDate),
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.w500)),
//                         const Spacer(),
//                         Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: systolicController,
//                   keyboardType: TextInputType.number,
//                   style: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.w500),
//                   decoration: InputDecoration(
//                     labelText: 'Systolic (Upper)',
//                     labelStyle: TextStyle(color: Colors.grey[600]),
//                     suffixText: 'mmHg',
//                     suffixStyle: TextStyle(
//                         color: Colors.grey[600], fontWeight: FontWeight.w600),
//                     // MIC ICON FOR SYSTOLIC
//                     prefixIcon: IconButton(
//                       icon: Icon(
//                         _isListening ? Icons.mic : Icons.mic_none,
//                         color: _isListening ? Colors.red : Colors.red[600],
//                       ),
//                       onPressed: () {
//                         if (_isListening) {
//                           _stopListening(setModalState);
//                         } else {
//                           _startListening(systolicController, setModalState);
//                         }
//                       },
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[50],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide.none,
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide(color: Colors.red[400]!, width: 2),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 18),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: diastolicController,
//                   keyboardType: TextInputType.number,
//                   style: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.w500),
//                   decoration: InputDecoration(
//                     labelText: 'Diastolic (Lower)',
//                     labelStyle: TextStyle(color: Colors.grey[600]),
//                     suffixText: 'mmHg',
//                     suffixStyle: TextStyle(
//                         color: Colors.grey[600], fontWeight: FontWeight.w600),
//                     // MIC ICON FOR DIASTOLIC
//                     prefixIcon: IconButton(
//                       icon: Icon(
//                         _isListening ? Icons.mic : Icons.mic_none,
//                         color: _isListening ? Colors.red : Colors.red[600],
//                       ),
//                       onPressed: () {
//                         if (_isListening) {
//                           _stopListening(setModalState);
//                         } else {
//                           _startListening(diastolicController, setModalState);
//                         }
//                       },
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[50],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide.none,
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide(color: Colors.red[400]!, width: 2),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 18),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                         child: Text('Cancel',
//                             style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey[700])),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       flex: 2,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.red[400]!, Colors.red[600]!],
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.red.withOpacity(0.3),
//                               blurRadius: 12,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             if (systolicController.text.isNotEmpty &&
//                                 diastolicController.text.isNotEmpty) {
//                               await _addBPEntry(
//                                   double.parse(systolicController.text),
//                                   double.parse(diastolicController.text),
//                                   selectedDate);
//                               Navigator.pop(context);
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                           ),
//                           child: const Text('Add Entry',
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void showNoteDialog(BuildContext context) {
//     final controller = TextEditingController();
//     DateTime selectedDate = DateTime.now();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//           ),
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 50,
//                   height: 5,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.blue[300]!, Colors.blue[500]!],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: const Icon(Icons.edit_note,
//                           color: Colors.white, size: 24),
//                     ),
//                     const SizedBox(width: 16),
//                     const Text('Add Note',
//                         style: TextStyle(
//                             fontSize: 22, fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 GestureDetector(
//                   onTap: () async {
//                     final date = await showDatePicker(
//                       context: context,
//                       initialDate: selectedDate,
//                       firstDate: DateTime(2020),
//                       lastDate: DateTime.now(),
//                       builder: (context, child) {
//                         return Theme(
//                           data: Theme.of(context).copyWith(
//                             colorScheme: ColorScheme.light(
//                               primary: Colors.blue[500]!,
//                               onPrimary: Colors.white,
//                             ),
//                           ),
//                           child: child!,
//                         );
//                       },
//                     );
//                     if (date != null) {
//                       setModalState(() => selectedDate = date);
//                     }
//                   },
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[50],
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.grey[200]!),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.calendar_today,
//                             color: Colors.blue[500], size: 20),
//                         const SizedBox(width: 12),
//                         Text(DateFormat('dd MMM yyyy').format(selectedDate),
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.w500)),
//                         const Spacer(),
//                         Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: controller,
//                   maxLines: 5,
//                   style: const TextStyle(fontSize: 16),
//                   decoration: InputDecoration(
//                     hintText: 'Write your health note here...',
//                     hintStyle: TextStyle(color: Colors.grey[400]),
//                     filled: true,
//                     fillColor: Colors.grey[50],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide.none,
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
//                     ),
//                     contentPadding: const EdgeInsets.all(20),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                         ),
//                         child: Text('Cancel',
//                             style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.grey[700])),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       flex: 2,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.blue[400]!, Colors.blue[600]!],
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.blue.withOpacity(0.3),
//                               blurRadius: 12,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             if (controller.text.isNotEmpty) {
//                               await _addNote(controller.text, selectedDate);
//                               Navigator.pop(context);
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                           ),
//                           child: const Text('Save Note',
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   double calculateSugarAverage() {
//     if (sugarEntries.isEmpty) return 0;
//     final now = DateTime.now();
//     final currentMonth = now.month;
//     final currentYear = now.year;

//     final currentMonthEntries = sugarEntries.where((entry) {
//       final entryDate = DateTime.parse(entry.date);
//       return entryDate.month == currentMonth && entryDate.year == currentYear;
//     }).toList();

//     if (currentMonthEntries.isEmpty) return 0;
//     final sum = currentMonthEntries.fold(0.0, (sum, entry) => sum + entry.value);
//     return sum / currentMonthEntries.length;
//   }

//   Map<String, double> calculateBPAverage() {
//     if (bpEntries.isEmpty) return {'systolic': 0, 'diastolic': 0};
//     final now = DateTime.now();
//     final currentMonth = now.month;
//     final currentYear = now.year;

//     final currentMonthEntries = bpEntries.where((entry) {
//       final entryDate = DateTime.parse(entry.date);
//       return entryDate.month == currentMonth && entryDate.year == currentYear;
//     }).toList();

//     if (currentMonthEntries.isEmpty) return {'systolic': 0, 'diastolic': 0};
//     final sumSys =
//         currentMonthEntries.fold(0.0, (sum, entry) => sum + entry.systolic);
//     final sumDia =
//         currentMonthEntries.fold(0.0, (sum, entry) => sum + entry.diastolic);
//     return {
//       'systolic': sumSys / currentMonthEntries.length,
//       'diastolic': sumDia / currentMonthEntries.length,
//     };
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bpAvg = calculateBPAverage();
//     final lastSugar = sugarEntries.isNotEmpty ? sugarEntries.first : null;
//     final lastBP = bpEntries.isNotEmpty ? bpEntries.first : null;

//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: Colors.grey[50],
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [Colors.green[400]!, Colors.green[600]!],
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Saarthi',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const ProfileScreen(),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.3),
//                               width: 2,
//                             ),
//                           ),
//                           child: const Icon(
//                             Icons.person_outline,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Stay healthy, stay happy! 💚',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.white.withOpacity(0.9),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Quick Actions',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildActionCard(
//                             context,
//                             'Blood Sugar',
//                             Icons.water_drop,
//                             [Colors.green[300]!, Colors.green[500]!],
//                             () => showSugarDialog(context),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildActionCard(
//                             context,
//                             'Blood Pressure',
//                             Icons.favorite,
//                             [Colors.red[300]!, Colors.red[500]!],
//                             () => showBPDialog(context),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     Container(
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 20,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               const SizedBox(width: 12),
//                               const Text(
//                                 'Your Statistics',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 20),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildStatCard(
//                                   'Sugar Avg',
//                                   '${calculateSugarAverage().toStringAsFixed(1)}',
//                                   'mg/dL',
//                                   Icons.trending_up,
//                                   [Colors.green[100]!, Colors.green[50]!],
//                                   Colors.green[600]!,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildStatCard(
//                                   'BP Avg',
//                                   '${bpAvg['systolic']!.toInt()}/${bpAvg['diastolic']!.toInt()}',
//                                   'mmHg',
//                                   Icons.favorite,
//                                   [Colors.red[100]!, Colors.red[50]!],
//                                   Colors.red[600]!,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'Recent Activity',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildRecentEntry(
//                       'Blood Sugar',
//                       '${lastSugar?.value ?? 0.0} mg/dL',
//                       lastSugar?.date ?? "No entries yet",
//                       Icons.water_drop,
//                       [Colors.green[100]!, Colors.green[50]!],
//                       Colors.green[600]!,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildRecentEntry(
//                       'Blood Pressure',
//                       '${lastBP?.systolic.toInt() ?? 0}/${lastBP?.diastolic.toInt() ?? 0} mmHg',
//                       lastBP?.date ?? "No entries yet",
//                       Icons.favorite,
//                       [Colors.red[100]!, Colors.red[50]!],
//                       Colors.red[600]!,
//                     ),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'Notes & Observations',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     GestureDetector(
//                       onTap: () => showNoteDialog(context),
//                       child: Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Colors.blue[50]!, Colors.blue[100]!],
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.blue[200]!, width: 1.5),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               child: Icon(Icons.add,
//                                   color: Colors.blue[600], size: 24),
//                             ),
//                             const SizedBox(width: 16),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Add a new note',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     'Track symptoms, meals & more',
//                                     style: TextStyle(
//                                         fontSize: 13, color: Colors.grey[600]),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Icon(Icons.arrow_forward_ios,
//                                 color: Colors.blue[400], size: 18),
//                           ],
//                         ),
//                       ),
//                     ),
//                     if (notes.isNotEmpty) ...[
//                       const SizedBox(height: 16),
//                       ...notes.take(3).map(
//                             (note) => Container(
//                               margin: const EdgeInsets.only(bottom: 12),
//                               padding: const EdgeInsets.all(20),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(20),
//                                 border:
//                                     Border.all(color: Colors.grey[200]!, width: 1),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.all(8),
//                                         decoration: BoxDecoration(
//                                           color: Colors.amber[50],
//                                           borderRadius: BorderRadius.circular(10),
//                                         ),
//                                         child: Icon(Icons.note,
//                                             color: Colors.amber[700], size: 18),
//                                       ),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Text(
//                                           note.text,
//                                           style: const TextStyle(
//                                             fontSize: 15,
//                                             fontWeight: FontWeight.w500,
//                                             height: 1.4,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 12),
//                                   Text(
//                                     DateFormat('dd MMM yyyy')
//                                         .format(DateTime.parse(note.date)),
//                                     style: TextStyle(
//                                         fontSize: 12, color: Colors.grey[500]),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                     ],
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionCard(BuildContext context, String title, IconData icon,
//       List<Color> gradientColors, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(colors: gradientColors),
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: gradientColors[1].withOpacity(0.3),
//               blurRadius: 12,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(icon, color: gradientColors[1], size: 28),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Add entry',
//               style:
//                   TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(String label, String value, String unit, IconData icon,
//       List<Color> bgColors, Color iconColor) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(colors: bgColors),
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: iconColor, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[700],
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: iconColor,
//             ),
//           ),
//           Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentEntry(String title, String value, String date,
//       IconData icon, List<Color> bgColors, Color iconColor) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 15,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(colors: bgColors),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Icon(icon, color: iconColor, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   date == "No entries yet"
//                       ? date
//                       : DateFormat('dd MMM yyyy').format(DateTime.parse(date)),
//                   style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// // import 'package:flutter/material.dart';
// // import 'package:health_care/Graph/GraphScreen.dart';
// // import 'package:health_care/profile/profile_screen.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:intl/intl.dart';

// // class HomeScreen extends StatefulWidget {
// //   const HomeScreen({Key? key}) : super(key: key);

// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }

// // class _HomeScreenState extends State<HomeScreen> {
// //   List<HealthEntry> sugarEntries = [];
// //   List<BPEntry> bpEntries = [];
// //   List<NoteEntry> notes = [];
// //   bool _isLoading = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadAllData();
// //   }

// //   Future<void> _loadAllData() async {
// //     setState(() => _isLoading = true);
// //     await Future.wait([_loadSugarEntries(), _loadBPEntries(), _loadNotes()]);
// //     setState(() => _isLoading = false);
// //   }

// //   Future<void> _loadSugarEntries() async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final userId = prefs.getString('userId');
// //       if (userId == null) return;

// //       final response = await Supabase.instance.client
// //           .from('health_entries')
// //           .select()
// //           .eq('user_id', userId)
// //           .order('entry_date', ascending: false);

// //       setState(() {
// //         sugarEntries =
// //             (response as List)
// //                 .map(
// //                   (entry) => HealthEntry(
// //                     id: entry['id'].toString(), // Convert to String
// //                     value: (entry['value'] as num).toDouble(),
// //                     date: entry['entry_date'],
// //                     timestamp:
// //                         entry['created_at'] != null
// //                             ? DateTime.parse(
// //                               entry['created_at'],
// //                             ).millisecondsSinceEpoch
// //                             : DateTime.now().millisecondsSinceEpoch,
// //                   ),
// //                 )
// //                 .toList();
// //       });
// //     } catch (e) {
// //       print('Error loading sugar entries: $e');
// //     }
// //   }

// //   Future<void> _loadBPEntries() async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final userId = prefs.getString('userId');
// //       if (userId == null) return;

// //       final response = await Supabase.instance.client
// //           .from('bp_entries')
// //           .select()
// //           .eq('user_id', userId)
// //           .order('entry_date', ascending: false);

// //       setState(() {
// //         bpEntries =
// //             (response as List)
// //                 .map(
// //                   (entry) => BPEntry(
// //                     id: entry['id'].toString(), // Convert to String
// //                     systolic: (entry['systolic'] as num).toDouble(),
// //                     diastolic: (entry['diastolic'] as num).toDouble(),
// //                     date: entry['entry_date'],
// //                     timestamp:
// //                         entry['created_at'] != null
// //                             ? DateTime.parse(
// //                               entry['created_at'],
// //                             ).millisecondsSinceEpoch
// //                             : DateTime.now().millisecondsSinceEpoch,
// //                   ),
// //                 )
// //                 .toList();
// //       });
// //     } catch (e) {
// //       print('Error loading BP entries: $e');
// //     }
// //   }

// //   Future<void> _loadNotes() async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final userId = prefs.getString('userId');
// //       if (userId == null) return;

// //       final response = await Supabase.instance.client
// //           .from('note_entries')
// //           .select()
// //           .eq('user_id', userId)
// //           .order('entry_date', ascending: false);

// //       setState(() {
// //         notes =
// //             (response as List)
// //                 .map(
// //                   (entry) => NoteEntry(
// //                     id: entry['id'].toString(), // Convert to String
// //                     text: entry['text'],
// //                     date: entry['entry_date'],
// //                     timestamp:
// //                         entry['created_at'] != null
// //                             ? DateTime.parse(
// //                               entry['created_at'],
// //                             ).millisecondsSinceEpoch
// //                             : DateTime.now().millisecondsSinceEpoch,
// //                   ),
// //                 )
// //                 .toList();
// //       });
// //     } catch (e) {
// //       print('Error loading notes: $e');
// //     }
// //   }
// //   // Future<void> _addSugarEntry(double value, DateTime date) async {
// //   //   try {
// //   //     final userId = Supabase.instance.client.auth.currentUser?.id;
// //   //     print('Current User ID: $userId');

// //   //     if (userId == null) {
// //   //       print('ERROR: User not logged in!');
// //   //       ScaffoldMessenger.of(
// //   //         context,
// //   //       ).showSnackBar(const SnackBar(content: Text('Please login first!')));
// //   //       return;
// //   //     }

// //   //     final dataToInsert = {
// //   //       'user_id': userId,
// //   //       'value': value,
// //   //       'entry_date': DateFormat('yyyy-MM-dd').format(date),
// //   //     };

// //   //     print('Inserting data: $dataToInsert');

// //   //     final response =
// //   //         await Supabase.instance.client
// //   //             .from('health_entries')
// //   //             .insert(dataToInsert)
// //   //             .select();

// //   //     print('Insert response: $response');

// //   //     ScaffoldMessenger.of(context).showSnackBar(
// //   //       const SnackBar(content: Text('Sugar entry added successfully!')),
// //   //     );

// //   //     await _loadSugarEntries();
// //   //   } catch (e) {
// //   //     print('ERROR adding sugar entry: $e');
// //   //     ScaffoldMessenger.of(
// //   //       context,
// //   //     ).showSnackBar(SnackBar(content: Text('Error: $e')));
// //   //   }
// //   // }
// //   Future<void> _addSugarEntry(double value, DateTime date) async {
// //     try {
// //       // SharedPreferences se userId lo
// //       final prefs = await SharedPreferences.getInstance();
// //       final userId = prefs.getString('userId');

// //       print('Current User ID from SharedPreferences: $userId');

// //       if (userId == null || userId.isEmpty) {
// //         print('ERROR: User not logged in!');
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text('Please login first!')));
// //         return;
// //       }

// //       final dataToInsert = {
// //         'user_id': userId,
// //         'value': value,
// //         'entry_date': DateFormat('yyyy-MM-dd').format(date),
// //       };

// //       print('Inserting data: $dataToInsert');

// //       final response =
// //           await Supabase.instance.client
// //               .from('health_entries')
// //               .insert(dataToInsert)
// //               .select();

// //       print('Insert response: $response');

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Sugar entry added successfully!')),
// //       );

// //       await _loadSugarEntries();
// //     } catch (e) {
// //       print('ERROR adding sugar entry: $e');
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// //     }
// //   }

// //   Future<void> _addBPEntry(
// //     double systolic,
// //     double diastolic,
// //     DateTime date,
// //   ) async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final userId = prefs.getString('userId');
// //       print('Current User ID: $userId');

// //       if (userId == null) {
// //         print('ERROR: User not logged in!');
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text('Please login first!')));
// //         return;
// //       }

// //       final dataToInsert = {
// //         'user_id': userId,
// //         'systolic': systolic,
// //         'diastolic': diastolic,
// //         'entry_date': DateFormat('yyyy-MM-dd').format(date),
// //       };

// //       print('Inserting BP data: $dataToInsert');

// //       final response =
// //           await Supabase.instance.client
// //               .from('bp_entries')
// //               .insert(dataToInsert)
// //               .select();

// //       print('BP Insert response: $response');

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('BP entry added successfully!')),
// //       );

// //       await _loadBPEntries();
// //     } catch (e) {
// //       print('ERROR adding BP entry: $e');
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// //     }
// //   }

// //   Future<void> _addNote(String text, DateTime date) async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final userId = prefs.getString('userId');
// //       print('Current User ID: $userId');

// //       if (userId == null) {
// //         print('ERROR: User not logged in!');
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text('Please login first!')));
// //         return;
// //       }

// //       final dataToInsert = {
// //         'user_id': userId,
// //         'text': text,
// //         'entry_date': DateFormat('yyyy-MM-dd').format(date),
// //       };

// //       print('Inserting note data: $dataToInsert');

// //       final response =
// //           await Supabase.instance.client
// //               .from('note_entries')
// //               .insert(dataToInsert)
// //               .select();

// //       print('Note Insert response: $response');

// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text('Note saved successfully!')));

// //       await _loadNotes();
// //     } catch (e) {
// //       print('ERROR adding note: $e');
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// //     }
// //   }

// //   void showSugarDialog(BuildContext context) {
// //     final controller = TextEditingController();
// //     DateTime selectedDate = DateTime.now();

// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder:
// //           (context) => StatefulBuilder(
// //             builder:
// //                 (context, setModalState) => Container(
// //                   decoration: const BoxDecoration(
// //                     color: Colors.white,
// //                     borderRadius: BorderRadius.vertical(
// //                       top: Radius.circular(30),
// //                     ),
// //                   ),
// //                   padding: EdgeInsets.only(
// //                     bottom: MediaQuery.of(context).viewInsets.bottom,
// //                   ),
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(24),
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         Container(
// //                           width: 50,
// //                           height: 5,
// //                           decoration: BoxDecoration(
// //                             color: Colors.grey[300],
// //                             borderRadius: BorderRadius.circular(3),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 24),
// //                         Row(
// //                           children: [
// //                             Container(
// //                               padding: const EdgeInsets.all(12),
// //                               decoration: BoxDecoration(
// //                                 gradient: LinearGradient(
// //                                   colors: [
// //                                     Colors.green[400]!,
// //                                     Colors.green[600]!,
// //                                   ],
// //                                 ),
// //                                 borderRadius: BorderRadius.circular(16),
// //                               ),
// //                               child: const Icon(
// //                                 Icons.water_drop,
// //                                 color: Colors.white,
// //                                 size: 24,
// //                               ),
// //                             ),
// //                             const SizedBox(width: 16),
// //                             const Text(
// //                               'Add Blood Sugar',
// //                               style: TextStyle(
// //                                 fontSize: 22,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 24),

// //                         // Date Picker
// //                         GestureDetector(
// //                           onTap: () async {
// //                             final date = await showDatePicker(
// //                               context: context,
// //                               initialDate: selectedDate,
// //                               firstDate: DateTime(2020),
// //                               lastDate: DateTime.now(),
// //                               builder: (context, child) {
// //                                 return Theme(
// //                                   data: Theme.of(context).copyWith(
// //                                     colorScheme: ColorScheme.light(
// //                                       primary: Colors.green[600]!,
// //                                       onPrimary: Colors.white,
// //                                     ),
// //                                   ),
// //                                   child: child!,
// //                                 );
// //                               },
// //                             );
// //                             if (date != null) {
// //                               setModalState(() => selectedDate = date);
// //                             }
// //                           },
// //                           child: Container(
// //                             padding: const EdgeInsets.symmetric(
// //                               horizontal: 20,
// //                               vertical: 18,
// //                             ),
// //                             decoration: BoxDecoration(
// //                               color: Colors.grey[50],
// //                               borderRadius: BorderRadius.circular(20),
// //                               border: Border.all(color: Colors.grey[200]!),
// //                             ),
// //                             child: Row(
// //                               children: [
// //                                 Icon(
// //                                   Icons.calendar_today,
// //                                   color: Colors.green[600],
// //                                   size: 20,
// //                                 ),
// //                                 const SizedBox(width: 12),
// //                                 Text(
// //                                   DateFormat(
// //                                     'dd MMM yyyy',
// //                                   ).format(selectedDate),
// //                                   style: const TextStyle(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.w500,
// //                                   ),
// //                                 ),
// //                                 const Spacer(),
// //                                 Icon(
// //                                   Icons.arrow_drop_down,
// //                                   color: Colors.grey[600],
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 16),

// //                         TextField(
// //                           controller: controller,
// //                           keyboardType: TextInputType.number,
// //                           style: const TextStyle(
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                           decoration: InputDecoration(
// //                             hintText: 'Enter glucose level',
// //                             hintStyle: TextStyle(color: Colors.grey[400]),
// //                             suffixText: 'mg/dL',
// //                             suffixStyle: TextStyle(
// //                               color: Colors.grey[600],
// //                               fontWeight: FontWeight.w600,
// //                             ),
// //                             filled: true,
// //                             fillColor: Colors.grey[50],
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                             focusedBorder: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide(
// //                                 color: Colors.green[400]!,
// //                                 width: 2,
// //                               ),
// //                             ),
// //                             contentPadding: const EdgeInsets.symmetric(
// //                               horizontal: 20,
// //                               vertical: 18,
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 24),
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: TextButton(
// //                                 onPressed: () => Navigator.pop(context),
// //                                 style: TextButton.styleFrom(
// //                                   padding: const EdgeInsets.symmetric(
// //                                     vertical: 16,
// //                                   ),
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(20),
// //                                   ),
// //                                 ),
// //                                 child: Text(
// //                                   'Cancel',
// //                                   style: TextStyle(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.w600,
// //                                     color: Colors.grey[700],
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                             const SizedBox(width: 12),
// //                             Expanded(
// //                               flex: 2,
// //                               child: Container(
// //                                 decoration: BoxDecoration(
// //                                   gradient: LinearGradient(
// //                                     colors: [
// //                                       Colors.green[400]!,
// //                                       Colors.green[600]!,
// //                                     ],
// //                                   ),
// //                                   borderRadius: BorderRadius.circular(20),
// //                                   boxShadow: [
// //                                     BoxShadow(
// //                                       color: Colors.green.withOpacity(0.3),
// //                                       blurRadius: 12,
// //                                       offset: const Offset(0, 4),
// //                                     ),
// //                                   ],
// //                                 ),
// //                                 child: ElevatedButton(
// //                                   onPressed: () async {
// //                                     if (controller.text.isNotEmpty) {
// //                                       await _addSugarEntry(
// //                                         double.parse(controller.text),
// //                                         selectedDate,
// //                                       );
// //                                       Navigator.pop(context);
// //                                     }
// //                                   },
// //                                   style: ElevatedButton.styleFrom(
// //                                     backgroundColor: Colors.transparent,
// //                                     foregroundColor: Colors.white,
// //                                     elevation: 0,
// //                                     padding: const EdgeInsets.symmetric(
// //                                       vertical: 16,
// //                                     ),
// //                                     shape: RoundedRectangleBorder(
// //                                       borderRadius: BorderRadius.circular(20),
// //                                     ),
// //                                   ),
// //                                   child: const Text(
// //                                     'Add Entry',
// //                                     style: TextStyle(
// //                                       fontSize: 16,
// //                                       fontWeight: FontWeight.bold,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //           ),
// //     );
// //   }

// //   void showBPDialog(BuildContext context) {
// //     final systolicController = TextEditingController();
// //     final diastolicController = TextEditingController();
// //     DateTime selectedDate = DateTime.now();

// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder:
// //           (context) => StatefulBuilder(
// //             builder:
// //                 (context, setModalState) => Container(
// //                   decoration: const BoxDecoration(
// //                     color: Colors.white,
// //                     borderRadius: BorderRadius.vertical(
// //                       top: Radius.circular(30),
// //                     ),
// //                   ),
// //                   padding: EdgeInsets.only(
// //                     bottom: MediaQuery.of(context).viewInsets.bottom,
// //                   ),
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(24),
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         Container(
// //                           width: 50,
// //                           height: 5,
// //                           decoration: BoxDecoration(
// //                             color: Colors.grey[300],
// //                             borderRadius: BorderRadius.circular(3),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 24),
// //                         Row(
// //                           children: [
// //                             Container(
// //                               padding: const EdgeInsets.all(12),
// //                               decoration: BoxDecoration(
// //                                 gradient: LinearGradient(
// //                                   colors: [Colors.red[300]!, Colors.red[500]!],
// //                                 ),
// //                                 borderRadius: BorderRadius.circular(16),
// //                               ),
// //                               child: const Icon(
// //                                 Icons.favorite,
// //                                 color: Colors.white,
// //                                 size: 24,
// //                               ),
// //                             ),
// //                             const SizedBox(width: 16),
// //                             const Text(
// //                               'Add Blood Pressure',
// //                               style: TextStyle(
// //                                 fontSize: 22,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 24),

// //                         // Date Picker
// //                         GestureDetector(
// //                           onTap: () async {
// //                             final date = await showDatePicker(
// //                               context: context,
// //                               initialDate: selectedDate,
// //                               firstDate: DateTime(2020),
// //                               lastDate: DateTime.now(),
// //                               builder: (context, child) {
// //                                 return Theme(
// //                                   data: Theme.of(context).copyWith(
// //                                     colorScheme: ColorScheme.light(
// //                                       primary: Colors.red[500]!,
// //                                       onPrimary: Colors.white,
// //                                     ),
// //                                   ),
// //                                   child: child!,
// //                                 );
// //                               },
// //                             );
// //                             if (date != null) {
// //                               setModalState(() => selectedDate = date);
// //                             }
// //                           },
// //                           child: Container(
// //                             padding: const EdgeInsets.symmetric(
// //                               horizontal: 20,
// //                               vertical: 18,
// //                             ),
// //                             decoration: BoxDecoration(
// //                               color: Colors.grey[50],
// //                               borderRadius: BorderRadius.circular(20),
// //                               border: Border.all(color: Colors.grey[200]!),
// //                             ),
// //                             child: Row(
// //                               children: [
// //                                 Icon(
// //                                   Icons.calendar_today,
// //                                   color: Colors.red[500],
// //                                   size: 20,
// //                                 ),
// //                                 const SizedBox(width: 12),
// //                                 Text(
// //                                   DateFormat(
// //                                     'dd MMM yyyy',
// //                                   ).format(selectedDate),
// //                                   style: const TextStyle(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.w500,
// //                                   ),
// //                                 ),
// //                                 const Spacer(),
// //                                 Icon(
// //                                   Icons.arrow_drop_down,
// //                                   color: Colors.grey[600],
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 16),

// //                         TextField(
// //                           controller: systolicController,
// //                           keyboardType: TextInputType.number,
// //                           style: const TextStyle(
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                           decoration: InputDecoration(
// //                             labelText: 'Systolic (Upper)',
// //                             labelStyle: TextStyle(color: Colors.grey[600]),
// //                             suffixText: 'mmHg',
// //                             suffixStyle: TextStyle(
// //                               color: Colors.grey[600],
// //                               fontWeight: FontWeight.w600,
// //                             ),
// //                             filled: true,
// //                             fillColor: Colors.grey[50],
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                             focusedBorder: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide(
// //                                 color: Colors.red[400]!,
// //                                 width: 2,
// //                               ),
// //                             ),
// //                             contentPadding: const EdgeInsets.symmetric(
// //                               horizontal: 20,
// //                               vertical: 18,
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 16),
// //                         TextField(
// //                           controller: diastolicController,
// //                           keyboardType: TextInputType.number,
// //                           style: const TextStyle(
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                           decoration: InputDecoration(
// //                             labelText: 'Diastolic (Lower)',
// //                             labelStyle: TextStyle(color: Colors.grey[600]),
// //                             suffixText: 'mmHg',
// //                             suffixStyle: TextStyle(
// //                               color: Colors.grey[600],
// //                               fontWeight: FontWeight.w600,
// //                             ),
// //                             filled: true,
// //                             fillColor: Colors.grey[50],
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                             focusedBorder: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide(
// //                                 color: Colors.red[400]!,
// //                                 width: 2,
// //                               ),
// //                             ),
// //                             contentPadding: const EdgeInsets.symmetric(
// //                               horizontal: 20,
// //                               vertical: 18,
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 24),
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: TextButton(
// //                                 onPressed: () => Navigator.pop(context),
// //                                 style: TextButton.styleFrom(
// //                                   padding: const EdgeInsets.symmetric(
// //                                     vertical: 16,
// //                                   ),
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(20),
// //                                   ),
// //                                 ),
// //                                 child: Text(
// //                                   'Cancel',
// //                                   style: TextStyle(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.w600,
// //                                     color: Colors.grey[700],
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                             const SizedBox(width: 12),
// //                             Expanded(
// //                               flex: 2,
// //                               child: Container(
// //                                 decoration: BoxDecoration(
// //                                   gradient: LinearGradient(
// //                                     colors: [
// //                                       Colors.red[400]!,
// //                                       Colors.red[600]!,
// //                                     ],
// //                                   ),
// //                                   borderRadius: BorderRadius.circular(20),
// //                                   boxShadow: [
// //                                     BoxShadow(
// //                                       color: Colors.red.withOpacity(0.3),
// //                                       blurRadius: 12,
// //                                       offset: const Offset(0, 4),
// //                                     ),
// //                                   ],
// //                                 ),
// //                                 child: ElevatedButton(
// //                                   onPressed: () async {
// //                                     if (systolicController.text.isNotEmpty &&
// //                                         diastolicController.text.isNotEmpty) {
// //                                       await _addBPEntry(
// //                                         double.parse(systolicController.text),
// //                                         double.parse(diastolicController.text),
// //                                         selectedDate,
// //                                       );
// //                                       Navigator.pop(context);
// //                                     }
// //                                   },
// //                                   style: ElevatedButton.styleFrom(
// //                                     backgroundColor: Colors.transparent,
// //                                     foregroundColor: Colors.white,
// //                                     elevation: 0,
// //                                     padding: const EdgeInsets.symmetric(
// //                                       vertical: 16,
// //                                     ),
// //                                     shape: RoundedRectangleBorder(
// //                                       borderRadius: BorderRadius.circular(20),
// //                                     ),
// //                                   ),
// //                                   child: const Text(
// //                                     'Add Entry',
// //                                     style: TextStyle(
// //                                       fontSize: 16,
// //                                       fontWeight: FontWeight.bold,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //           ),
// //     );
// //   }

// //   void showNoteDialog(BuildContext context) {
// //     final controller = TextEditingController();
// //     DateTime selectedDate = DateTime.now();

// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder:
// //           (context) => StatefulBuilder(
// //             builder:
// //                 (context, setModalState) => Container(
// //                   decoration: const BoxDecoration(
// //                     color: Colors.white,
// //                     borderRadius: BorderRadius.vertical(
// //                       top: Radius.circular(30),
// //                     ),
// //                   ),
// //                   padding: EdgeInsets.only(
// //                     bottom: MediaQuery.of(context).viewInsets.bottom,
// //                   ),
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(24),
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         Container(
// //                           width: 50,
// //                           height: 5,
// //                           decoration: BoxDecoration(
// //                             color: Colors.grey[300],
// //                             borderRadius: BorderRadius.circular(3),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 24),
// //                         Row(
// //                           children: [
// //                             Container(
// //                               padding: const EdgeInsets.all(12),
// //                               decoration: BoxDecoration(
// //                                 gradient: LinearGradient(
// //                                   colors: [
// //                                     Colors.blue[300]!,
// //                                     Colors.blue[500]!,
// //                                   ],
// //                                 ),
// //                                 borderRadius: BorderRadius.circular(16),
// //                               ),
// //                               child: const Icon(
// //                                 Icons.edit_note,
// //                                 color: Colors.white,
// //                                 size: 24,
// //                               ),
// //                             ),
// //                             const SizedBox(width: 16),
// //                             const Text(
// //                               'Add Note',
// //                               style: TextStyle(
// //                                 fontSize: 22,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 24),

// //                         // Date Picker
// //                         GestureDetector(
// //                           onTap: () async {
// //                             final date = await showDatePicker(
// //                               context: context,
// //                               initialDate: selectedDate,
// //                               firstDate: DateTime(2020),
// //                               lastDate: DateTime.now(),
// //                               builder: (context, child) {
// //                                 return Theme(
// //                                   data: Theme.of(context).copyWith(
// //                                     colorScheme: ColorScheme.light(
// //                                       primary: Colors.blue[500]!,
// //                                       onPrimary: Colors.white,
// //                                     ),
// //                                   ),
// //                                   child: child!,
// //                                 );
// //                               },
// //                             );
// //                             if (date != null) {
// //                               setModalState(() => selectedDate = date);
// //                             }
// //                           },
// //                           child: Container(
// //                             padding: const EdgeInsets.symmetric(
// //                               horizontal: 20,
// //                               vertical: 18,
// //                             ),
// //                             decoration: BoxDecoration(
// //                               color: Colors.grey[50],
// //                               borderRadius: BorderRadius.circular(20),
// //                               border: Border.all(color: Colors.grey[200]!),
// //                             ),
// //                             child: Row(
// //                               children: [
// //                                 Icon(
// //                                   Icons.calendar_today,
// //                                   color: Colors.blue[500],
// //                                   size: 20,
// //                                 ),
// //                                 const SizedBox(width: 12),
// //                                 Text(
// //                                   DateFormat(
// //                                     'dd MMM yyyy',
// //                                   ).format(selectedDate),
// //                                   style: const TextStyle(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.w500,
// //                                   ),
// //                                 ),
// //                                 const Spacer(),
// //                                 Icon(
// //                                   Icons.arrow_drop_down,
// //                                   color: Colors.grey[600],
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 16),

// //                         TextField(
// //                           controller: controller,
// //                           maxLines: 5,
// //                           style: const TextStyle(fontSize: 16),
// //                           decoration: InputDecoration(
// //                             hintText: 'Write your health note here...',
// //                             hintStyle: TextStyle(color: Colors.grey[400]),
// //                             filled: true,
// //                             fillColor: Colors.grey[50],
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                             focusedBorder: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(20),
// //                               borderSide: BorderSide(
// //                                 color: Colors.blue[400]!,
// //                                 width: 2,
// //                               ),
// //                             ),
// //                             contentPadding: const EdgeInsets.all(20),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 24),
// //                         Row(
// //                           children: [
// //                             Expanded(
// //                               child: TextButton(
// //                                 onPressed: () => Navigator.pop(context),
// //                                 style: TextButton.styleFrom(
// //                                   padding: const EdgeInsets.symmetric(
// //                                     vertical: 16,
// //                                   ),
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(20),
// //                                   ),
// //                                 ),
// //                                 child: Text(
// //                                   'Cancel',
// //                                   style: TextStyle(
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.w600,
// //                                     color: Colors.grey[700],
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                             const SizedBox(width: 12),
// //                             Expanded(
// //                               flex: 2,
// //                               child: Container(
// //                                 decoration: BoxDecoration(
// //                                   gradient: LinearGradient(
// //                                     colors: [
// //                                       Colors.blue[400]!,
// //                                       Colors.blue[600]!,
// //                                     ],
// //                                   ),
// //                                   borderRadius: BorderRadius.circular(20),
// //                                   boxShadow: [
// //                                     BoxShadow(
// //                                       color: Colors.blue.withOpacity(0.3),
// //                                       blurRadius: 12,
// //                                       offset: const Offset(0, 4),
// //                                     ),
// //                                   ],
// //                                 ),
// //                                 child: ElevatedButton(
// //                                   onPressed: () async {
// //                                     if (controller.text.isNotEmpty) {
// //                                       await _addNote(
// //                                         controller.text,
// //                                         selectedDate,
// //                                       );
// //                                       Navigator.pop(context);
// //                                     }
// //                                   },
// //                                   style: ElevatedButton.styleFrom(
// //                                     backgroundColor: Colors.transparent,
// //                                     foregroundColor: Colors.white,
// //                                     elevation: 0,
// //                                     padding: const EdgeInsets.symmetric(
// //                                       vertical: 16,
// //                                     ),
// //                                     shape: RoundedRectangleBorder(
// //                                       borderRadius: BorderRadius.circular(20),
// //                                     ),
// //                                   ),
// //                                   child: const Text(
// //                                     'Save Note',
// //                                     style: TextStyle(
// //                                       fontSize: 16,
// //                                       fontWeight: FontWeight.bold,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //           ),
// //     );
// //   }

// //   double calculateSugarAverage() {
// //     if (sugarEntries.isEmpty) return 0;

// //     // Get current month and year
// //     final now = DateTime.now();
// //     final currentMonth = now.month;
// //     final currentYear = now.year;

// //     // Filter entries for current month only
// //     final currentMonthEntries =
// //         sugarEntries.where((entry) {
// //           final entryDate = DateTime.parse(entry.date);
// //           return entryDate.month == currentMonth &&
// //               entryDate.year == currentYear;
// //         }).toList();

// //     if (currentMonthEntries.isEmpty) return 0;

// //     final sum = currentMonthEntries.fold(
// //       0.0,
// //       (sum, entry) => sum + entry.value,
// //     );
// //     return sum / currentMonthEntries.length;
// //   }

// //   Map<String, double> calculateBPAverage() {
// //     if (bpEntries.isEmpty) return {'systolic': 0, 'diastolic': 0};

// //     // Get current month and year
// //     final now = DateTime.now();
// //     final currentMonth = now.month;
// //     final currentYear = now.year;

// //     // Filter entries for current month only
// //     final currentMonthEntries =
// //         bpEntries.where((entry) {
// //           final entryDate = DateTime.parse(entry.date);
// //           return entryDate.month == currentMonth &&
// //               entryDate.year == currentYear;
// //         }).toList();

// //     if (currentMonthEntries.isEmpty) return {'systolic': 0, 'diastolic': 0};

// //     final sumSys = currentMonthEntries.fold(
// //       0.0,
// //       (sum, entry) => sum + entry.systolic,
// //     );
// //     final sumDia = currentMonthEntries.fold(
// //       0.0,
// //       (sum, entry) => sum + entry.diastolic,
// //     );
// //     return {
// //       'systolic': sumSys / currentMonthEntries.length,
// //       'diastolic': sumDia / currentMonthEntries.length,
// //     };
// //   }

// //   // Map<String, double> calculateBPAverage() {
// //   //   if (bpEntries.isEmpty) return {'systolic': 0, 'diastolic': 0};
// //   //   final sumSys = bpEntries.fold(0.0, (sum, entry) => sum + entry.systolic);
// //   //   final sumDia = bpEntries.fold(0.0, (sum, entry) => sum + entry.diastolic);
// //   //   return {
// //   //     'systolic': sumSys / bpEntries.length,
// //   //     'diastolic': sumDia / bpEntries.length,
// //   //   };
// //   // }

// //   @override
// //   Widget build(BuildContext context) {
// //     final bpAvg = calculateBPAverage();
// //     final lastSugar = sugarEntries.isNotEmpty ? sugarEntries.first : null;
// //     final lastBP = bpEntries.isNotEmpty ? bpEntries.first : null;

// //     if (_isLoading) {
// //       return Scaffold(
// //         backgroundColor: Colors.grey[50],
// //         body: const Center(child: CircularProgressIndicator()),
// //       );
// //     }

// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Header with gradient
// //             Container(
// //               padding: const EdgeInsets.all(24),
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                   colors: [Colors.green[400]!, Colors.green[600]!],
// //                 ),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [],
// //                   ),
// //                   // const SizedBox(height: 24),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       const Text(
// //                         'Saarthi',
// //                         style: TextStyle(
// //                           fontSize: 32,
// //                           fontWeight: FontWeight.bold,
// //                           color: Colors.white,
// //                         ),
// //                       ),
// //                       GestureDetector(
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(
// //                               builder: (context) => const ProfileScreen(),
// //                             ),
// //                           );
// //                         },
// //                         child: Container(
// //                           decoration: BoxDecoration(
// //                             color: Colors.white.withOpacity(0.2),
// //                             shape: BoxShape.circle,
// //                             border: Border.all(
// //                               color: Colors.white.withOpacity(0.3),
// //                               width: 2,
// //                             ),
// //                           ),
// //                           child: const Icon(
// //                             Icons.person_outline,
// //                             color: Colors.white,
// //                             size: 24,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Text(
// //                     'Stay healthy, stay happy! 💚',
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       color: Colors.white.withOpacity(0.9),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             // Content
// //             Expanded(
// //               child: SingleChildScrollView(
// //                 padding: const EdgeInsets.all(24),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     // Quick Actions Grid
// //                     const Text(
// //                       'Quick Actions',
// //                       style: TextStyle(
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     Row(
// //                       children: [
// //                         Expanded(
// //                           child: _buildActionCard(
// //                             context,
// //                             'Blood Sugar',
// //                             Icons.water_drop,
// //                             [Colors.green[300]!, Colors.green[500]!],
// //                             () => showSugarDialog(context),
// //                           ),
// //                         ),
// //                         const SizedBox(width: 12),
// //                         Expanded(
// //                           child: _buildActionCard(
// //                             context,
// //                             'Blood Pressure',
// //                             Icons.favorite,
// //                             [Colors.red[300]!, Colors.red[500]!],
// //                             () => showBPDialog(context),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 24),
// //                     // Statistics Cards
// //                     Container(
// //                       padding: const EdgeInsets.all(24),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white,
// //                         borderRadius: BorderRadius.circular(24),
// //                         boxShadow: [
// //                           BoxShadow(
// //                             color: Colors.black.withOpacity(0.05),
// //                             blurRadius: 20,
// //                             offset: const Offset(0, 4),
// //                           ),
// //                         ],
// //                       ),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Row(
// //                             children: [
// //                               const SizedBox(width: 12),
// //                               const Text(
// //                                 'Your Statistics',
// //                                 style: TextStyle(
// //                                   fontWeight: FontWeight.bold,
// //                                   fontSize: 18,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                           const SizedBox(height: 20),
// //                           Row(
// //                             children: [
// //                               Expanded(
// //                                 child: _buildStatCard(
// //                                   'Sugar Avg',
// //                                   '${calculateSugarAverage().toStringAsFixed(1)}',
// //                                   'mg/dL',
// //                                   Icons.trending_up,
// //                                   [Colors.green[100]!, Colors.green[50]!],
// //                                   Colors.green[600]!,
// //                                 ),
// //                               ),
// //                               const SizedBox(width: 12),
// //                               Expanded(
// //                                 child: _buildStatCard(
// //                                   'BP Avg',
// //                                   '${bpAvg['systolic']!.toInt()}/${bpAvg['diastolic']!.toInt()}',
// //                                   'mmHg',
// //                                   Icons.favorite,
// //                                   [Colors.red[100]!, Colors.red[50]!],
// //                                   Colors.red[600]!,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     const SizedBox(height: 24),
// //                     const Text(
// //                       'Recent Activity',
// //                       style: TextStyle(
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     _buildRecentEntry(
// //                       'Blood Sugar',
// //                       '${lastSugar?.value ?? 0.0} mg/dL',
// //                       lastSugar?.date ?? "No entries yet",
// //                       Icons.water_drop,
// //                       [Colors.green[100]!, Colors.green[50]!],
// //                       Colors.green[600]!,
// //                     ),
// //                     const SizedBox(height: 12),
// //                     _buildRecentEntry(
// //                       'Blood Pressure',
// //                       '${lastBP?.systolic.toInt() ?? 0}/${lastBP?.diastolic.toInt() ?? 0} mmHg',
// //                       lastBP?.date ?? "No entries yet",
// //                       Icons.favorite,
// //                       [Colors.red[100]!, Colors.red[50]!],
// //                       Colors.red[600]!,
// //                     ),

// //                     // Notes Section
// //                     const SizedBox(height: 24),
// //                     const Text(
// //                       'Notes & Observations',
// //                       style: TextStyle(
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     GestureDetector(
// //                       onTap: () => showNoteDialog(context),
// //                       child: Container(
// //                         padding: const EdgeInsets.all(20),
// //                         decoration: BoxDecoration(
// //                           gradient: LinearGradient(
// //                             colors: [Colors.blue[50]!, Colors.blue[100]!],
// //                           ),
// //                           borderRadius: BorderRadius.circular(20),
// //                           border: Border.all(
// //                             color: Colors.blue[200]!,
// //                             width: 1.5,
// //                           ),
// //                         ),
// //                         child: Row(
// //                           children: [
// //                             Container(
// //                               padding: const EdgeInsets.all(12),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.white,
// //                                 borderRadius: BorderRadius.circular(14),
// //                               ),
// //                               child: Icon(
// //                                 Icons.add,
// //                                 color: Colors.blue[600],
// //                                 size: 24,
// //                               ),
// //                             ),
// //                             const SizedBox(width: 16),
// //                             Expanded(
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 children: [
// //                                   const Text(
// //                                     'Add a new note',
// //                                     style: TextStyle(
// //                                       fontWeight: FontWeight.bold,
// //                                       fontSize: 16,
// //                                     ),
// //                                   ),
// //                                   const SizedBox(height: 4),
// //                                   Text(
// //                                     'Track symptoms, meals & more',
// //                                     style: TextStyle(
// //                                       fontSize: 13,
// //                                       color: Colors.grey[600],
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                             Icon(
// //                               Icons.arrow_forward_ios,
// //                               color: Colors.blue[400],
// //                               size: 18,
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                     // Recent Notes
// //                     if (notes.isNotEmpty) ...[
// //                       const SizedBox(height: 16),
// //                       ...notes
// //                           .take(3)
// //                           .map(
// //                             (note) => Container(
// //                               margin: const EdgeInsets.only(bottom: 12),
// //                               padding: const EdgeInsets.all(20),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.white,
// //                                 borderRadius: BorderRadius.circular(20),
// //                                 border: Border.all(
// //                                   color: Colors.grey[200]!,
// //                                   width: 1,
// //                                 ),
// //                               ),
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 children: [
// //                                   Row(
// //                                     children: [
// //                                       Container(
// //                                         padding: const EdgeInsets.all(8),
// //                                         decoration: BoxDecoration(
// //                                           color: Colors.amber[50],
// //                                           borderRadius: BorderRadius.circular(
// //                                             10,
// //                                           ),
// //                                         ),
// //                                         child: Icon(
// //                                           Icons.note,
// //                                           color: Colors.amber[700],
// //                                           size: 18,
// //                                         ),
// //                                       ),
// //                                       const SizedBox(width: 12),
// //                                       Expanded(
// //                                         child: Text(
// //                                           note.text,
// //                                           style: const TextStyle(
// //                                             fontSize: 15,
// //                                             fontWeight: FontWeight.w500,
// //                                             height: 1.4,
// //                                           ),
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                   const SizedBox(height: 12),
// //                                   Text(
// //                                     DateFormat(
// //                                       'dd MMM yyyy',
// //                                     ).format(DateTime.parse(note.date)),
// //                                     style: TextStyle(
// //                                       fontSize: 12,
// //                                       color: Colors.grey[500],
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                     ],
// //                     const SizedBox(height: 24),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildActionCard(
// //     BuildContext context,
// //     String title,
// //     IconData icon,
// //     List<Color> gradientColors,
// //     VoidCallback onTap,
// //   ) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.all(20),
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(colors: gradientColors),
// //           borderRadius: BorderRadius.circular(24),
// //           boxShadow: [
// //             BoxShadow(
// //               color: gradientColors[1].withOpacity(0.3),
// //               blurRadius: 12,
// //               offset: const Offset(0, 6),
// //             ),
// //           ],
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: Colors.white.withOpacity(0.9),
// //                 borderRadius: BorderRadius.circular(14),
// //               ),
// //               child: Icon(icon, color: gradientColors[1], size: 28),
// //             ),
// //             const SizedBox(height: 16),
// //             Text(
// //               title,
// //               style: const TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //                 color: Colors.white,
// //               ),
// //             ),
// //             const SizedBox(height: 4),
// //             Text(
// //               'Add entry',
// //               style: TextStyle(
// //                 fontSize: 13,
// //                 color: Colors.white.withOpacity(0.9),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildStatCard(
// //     String label,
// //     String value,
// //     String unit,
// //     IconData icon,
// //     List<Color> bgColors,
// //     Color iconColor,
// //   ) {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(colors: bgColors),
// //         borderRadius: BorderRadius.circular(18),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(icon, color: iconColor, size: 18),
// //               const SizedBox(width: 6),
// //               Text(
// //                 label,
// //                 style: TextStyle(
// //                   fontSize: 12,
// //                   color: Colors.grey[700],
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Text(
// //             value,
// //             style: TextStyle(
// //               fontSize: 26,
// //               fontWeight: FontWeight.bold,
// //               color: iconColor,
// //             ),
// //           ),
// //           Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildRecentEntry(
// //     String title,
// //     String value,
// //     String date,
// //     IconData icon,
// //     List<Color> bgColors,
// //     Color iconColor,
// //   ) {
// //     return Container(
// //       padding: const EdgeInsets.all(20),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(20),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.04),
// //             blurRadius: 15,
// //             offset: const Offset(0, 4),
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             padding: const EdgeInsets.all(14),
// //             decoration: BoxDecoration(
// //               gradient: LinearGradient(colors: bgColors),
// //               borderRadius: BorderRadius.circular(16),
// //             ),
// //             child: Icon(icon, color: iconColor, size: 24),
// //           ),
// //           const SizedBox(width: 16),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   title,
// //                   style: TextStyle(
// //                     fontSize: 13,
// //                     color: Colors.grey[600],
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   value,
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 18,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   date == "No entries yet"
// //                       ? date
// //                       : DateFormat('dd MMM yyyy').format(DateTime.parse(date)),
// //                   style: TextStyle(fontSize: 12, color: Colors.grey[500]),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
