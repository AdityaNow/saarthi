import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GraphScreen extends StatefulWidget {
  // final List<HealthEntry> sugarData;
  // final List<BPEntry> bpData;
  // final List<NoteEntry> notes;
  // final List<HealthEntry> sugarEntries;
  // final List<BPEntry> bpEntries;

  const GraphScreen({
    Key? key,
    // required this.sugarEntries,
    // required this.bpEntries,
    // required this.sugarData,
    // required this.bpData,
    // required this.notes,
  }) : super(key: key);

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<HealthMetricEntry> heartRateEntries = [];
  List<HealthMetricEntry> pulseEntries = [];
  List<HealthMetricEntry> temperatureEntries = [];
  List<HealthMetricEntry> weightEntries = [];
  List<HealthMetricEntry> heightEntries = [];
  List<HealthMetricEntry> wbcEntries = [];
  List<CBCEntry> cbcEntries = [];

  // Health metrics configuration
  final List<Map<String, dynamic>> healthMetrics = [
    {
      'type': 'Sugar',
      'label': 'Blood Sugar',
      'icon': Icons.water_drop,
      'color': Colors.green,
      'unit': 'mg/dL',
      'table': 'health_entries',
    },
    {
      'type': 'BP',
      'label': 'Blood Pressure',
      'icon': Icons.favorite,
      'color': Colors.red,
      'unit': 'mmHg',
      'table': 'bp_entries',
    },
    {
      'type': 'HeartRate',
      'label': 'Heart Rate',
      'icon': Icons.monitor_heart,
      'color': Colors.pink,
      'unit': 'bpm',
      'table': 'heart_rate_entries',
    },
    {
      'type': 'Pulse',
      'label': 'Pulse',
      'icon': Icons.graphic_eq,
      'color': Colors.purple,
      'unit': 'bpm',
      'table': 'pulse_entries',
    },
    {
      'type': 'Temperature',
      'label': 'Temperature',
      'icon': Icons.thermostat,
      'color': Colors.orange,
      'unit': '°C',
      'table': 'temperature_entries',
    },
    {
      'type': 'Weight',
      'label': 'Weight',
      'icon': Icons.monitor_weight,
      'color': Colors.blue,
      'unit': 'kg',
      'table': 'weight_entries',
    },
    {
      'type': 'CBC',
      'label': 'CBC',
      'icon': Icons.bloodtype,
      'color': Colors.deepPurple,
      'unit': 'cells/μL',
      'table': 'cbc_entries',
    },
  ];
  List<HealthMetricEntry> sugarEntries = [];
  // List<HealthMetricEntry> temperatureEntries = [];
  List<BPEntry> bpEntries = [];
  List<NoteEntry> notes = [];
  List<NoteEntry> _notes = [];
  bool _isLoading = true;
  // late stt.SpeechToText _speech;
  bool _isListening = false;
  String _listeningField = '';
  String? _errorMessage;
  List<HealthEntry> _sugarEntries = [];
  List<BPEntry> _bpEntries = [];
  final SupabaseClient supabase = Supabase.instance.client;
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
          weightEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
    }
  }

  // Track which field is listening
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
          temperatureEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
    }
  }

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
        _loadHeartRateEntries(),
        _loadPulseEntries(),
        _loadTempratureEntries(),
        _loadWeightEntries(),
        _loadHeightEntries(),
        _loadCBCEntries(),
        _loadWBCEntries(),

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

  // === SUPABASE INDIVIDUAL LOAD FUNCTIONS (using user's provided logic) ===
  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      // final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('note_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false);

      setState(() {
        notes =
            (response as List)
                .map(
                  (entry) => NoteEntry(
                    id: entry['id'].toString(), // Convert to String
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
      });
    } catch (e) {
      print('Error loading notes: $e');
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
          .order('meal_time', ascending: true);

      setState(() {
        sugarEntries =
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
                            : DateTime.now().millisecondsSinceEpoch,
                    timeOfDay: entry['time_of_day'],
                    mealTime: entry['meal_time'],
                  ),
                )
                .toList();
      });
    } catch (e) {
      print('Error loading sugar entries: $e');
    }
  }

  Future<void> _loadBPEntries() async {
    // final userId = supabase.auth.currentUser?.id;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return;

    try {
      final response = await supabase
          .from('bp_entries')
          .select()
          .eq('user_id', userId)
          .order(
            'entry_date',
            ascending: true,
          ); // Ascending for graph rendering

      final List<BPEntry> fetchedBP =
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
                          : null,
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          bpEntries = fetchedBP;
        });
      }
    } catch (e) {
      print('Error loading BP entries: $e');
      throw Exception(
        'BP data fetch failed',
      ); // Throw to be caught by _fetchEntries
    }
  }

  String selectedType = 'Sugar';
  String selectedMonth = 'All Time';
  List<String> availableMonths = [];

  // 🎯 Touch interaction variables
  int? selectedSugarIndex;
  int? selectedBPIndex;

  @override
  void initState() {
    super.initState();
    _fetchEntries();
    _loadNotes(); // Start fetching data from Supabase on screen load
    _generateAvailableMonths();
  }

  void _generateAvailableMonths() {
    final Set<String> months = {};
    months.add('All Time');
    months.add('Current Month');

    for (var entry in sugarEntries) {
      final date = DateTime.parse(entry.date);
      final monthYear = DateFormat('MMMM yyyy').format(date);
      months.add(monthYear);
    }

    for (var entry in bpEntries) {
      final date = DateTime.parse(entry.date);
      final monthYear = DateFormat('MMMM yyyy').format(date);
      months.add(monthYear);
    }

    setState(() {
      availableMonths = months.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMetricData = _getCurrentMetricData();

    final bool isDataEmpty = currentMetricData.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Graph Screen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'View your trends 📈',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              _buildTypeSelectionButtons(),
              const SizedBox(height: 24),
              _buildMonthDropdown(),
              const SizedBox(height: 24),
              _buildGraphContainer(currentMetricData, isDataEmpty),
              const SizedBox(height: 24),
              _buildStatsSummary(currentMetricData),
              const SizedBox(height: 24),
              _buildRecentEntriesList(currentMetricData),
            ],
          ),
        ),
      ),
    );
  }

  List<BPEntry> _filterBPEntries() {
    final now = DateTime.now();

    if (selectedMonth == 'All Time') {
      return bpEntries;
    } else if (selectedMonth == 'Current Month') {
      return bpEntries.where((e) {
        final date = DateTime.parse(e.date);
        return date.month == now.month && date.year == now.year;
      }).toList();
    } else {
      try {
        final selectedDate = DateFormat('MMMM yyyy').parse(selectedMonth);
        return bpEntries.where((e) {
          final date = DateTime.parse(e.date);
          return date.month == selectedDate.month &&
              date.year == selectedDate.year;
        }).toList();
      } catch (e) {
        return [];
      }
    }
  }

  Widget _buildTypeSelectionButtons() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: healthMetrics.length,
        itemBuilder: (context, index) {
          final metric = healthMetrics[index];
          final isSelected = selectedType == metric['type'];

          return GestureDetector(
            onTap:
                () => setState(() {
                  selectedType = metric['type'];
                  selectedSugarIndex = null;
                  selectedBPIndex = null;
                }),
            child: Container(
              width: 140,
              margin: EdgeInsets.only(
                right: index < healthMetrics.length - 1 ? 12 : 0,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? metric['color'] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? metric['color'] : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: metric['color'].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    metric['icon'],
                    color: isSelected ? Colors.white : metric['color'],
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metric['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadHeartRateEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final response = await supabase
          .from('heart_rate_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: true);

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
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          heartRateEntries = fetched;
        });
      }
    } catch (e) {
      print('Error loading heart rate entries: $e');
    }
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          isExpanded: true,
          icon: Icon(Icons.calendar_today, color: Colors.green[600], size: 20),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          items:
              availableMonths.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedMonth = newValue;
                selectedSugarIndex = null;
                selectedBPIndex = null;
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> generatePdf() async {
    final prefs = await SharedPreferences.getInstance();
    String userName = prefs.getString('userEmail') ?? "N/A";

    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );

    final sectionTitle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      decoration: pw.TextDecoration.underline,
    );

    final tableHeaderStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build:
            (context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Saarthi Records", style: titleStyle),
                      pw.Text("Indore, MP"),
                      pw.Text("Phone: +91 99999 88888"),
                    ],
                  ),
                  pw.Container(
                    width: 70,
                    height: 70,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Center(child: pw.Text("LOGO")),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Patient Information", style: sectionTitle),
                    pw.SizedBox(height: 8),
                    pw.Text("Email: $userName"),
                    pw.Text(
                      "Report Date: ${DateTime.now().toString().split(' ').first}",
                    ),

                    //                     pw.SizedBox(height: 20),
                    // pw.Text("Today Summary", style: sectionTitle),
                    // pw.SizedBox(height: 10),

                    // pw.Table(
                    //   border: pw.TableBorder.all(width: 1),
                    //   columnWidths: {
                    //     0: const pw.FlexColumnWidth(2),
                    //     1: const pw.FlexColumnWidth(3),
                    //   },
                    //   children: [
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("Sugar"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todaySugar.toString()),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("BP"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("$todaySystolic / $todayDiastolic"),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("WBC"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todayWBC.toString()),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("RBC"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todayRBC.toString()),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("Hemoglobin"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todayHB.toString()),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("Platelets"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todayPLT.toString()),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("Weight"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todayWeight.toString()),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("Height"),
                    //       ),

                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("Temperature"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todayTemperature.toString()),
                    //       ),
                    //     ]),
                    //     pw.TableRow(children: [
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text("Pulse / Heart Rate"),
                    //       ),
                    //       pw.Padding(
                    //         padding: const pw.EdgeInsets.all(8),
                    //         child: pw.Text(todayPulse.toString()),
                    //       ),
                    //     ]),
                    //   ],
                    // ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),
              pw.Text("Blood Sugar Report", style: sectionTitle),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ["Date", "Sugar (mg/dL)"],
                headerStyle: tableHeaderStyle,
                border: pw.TableBorder.all(width: 1),
                cellAlignment: pw.Alignment.centerLeft,
                data:
                    sugarEntries
                        .map((e) => [e.date.toString(), e.value.toString()])
                        .toList(),
              ),

              pw.SizedBox(height: 25),
              pw.SizedBox(height: 25),
              pw.Text("CBC Report", style: sectionTitle),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Date", "WBC", "RBC"],
                headerStyle: tableHeaderStyle,
                border: pw.TableBorder.all(width: 1),
                cellAlignment: pw.Alignment.centerLeft,
                data:
                    cbcEntries
                        .map(
                          (e) => [e.date, e.wbc.toString(), e.rbc.toString()],
                        )
                        .toList(),
              ),

              pw.SizedBox(height: 25),
              pw.SizedBox(height: 25),
              pw.Text("Weight Report", style: sectionTitle),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Date", "Weight (kg)"],
                headerStyle: tableHeaderStyle,
                border: pw.TableBorder.all(width: 1),
                data:
                    weightEntries
                        .map((e) => [e.date, e.value.toString()])
                        .toList(),
              ),

              pw.SizedBox(height: 25),
              pw.SizedBox(height: 25),
              pw.Text("Pulse / Heart Rate Report", style: sectionTitle),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Date", "Pulse (bpm)"],
                data:
                    pulseEntries
                        .map((e) => [e.date, e.value.toString()])
                        .toList(),
              ),

              pw.SizedBox(height: 25),
              pw.SizedBox(height: 25),
              pw.Text("Temperature Report", style: sectionTitle),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Date", "Temp (°C)"],
                data:
                    temperatureEntries
                        .map((e) => [e.date, e.value.toString()])
                        .toList(),
              ),

              pw.SizedBox(height: 25),
              pw.Text("Blood Pressure Report", style: sectionTitle),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ["Date", "Systolic", "Diastolic"],
                headerStyle: tableHeaderStyle,
                border: pw.TableBorder.all(width: 1),
                data:
                    bpEntries
                        .map(
                          (e) => [
                            e.date,
                            e.systolic.toString(),
                            e.diastolic.toString(),
                          ],
                        )
                        .toList(),
              ),
              pw.SizedBox(height: 25),
              if (notes.isNotEmpty) ...[
                pw.Text("Notes", style: sectionTitle),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children:
                        notes
                            .map(
                              (n) => pw.Text(
                                "- ${n.date} : ${n.text}",
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
              pw.SizedBox(height: 40),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("This is a system-generated report.")),
            ],
      ),
    );

    var status = await Permission.storage.request();
    if (!status.isGranted) return;

    Directory? downloadDir = Directory("/storage/emulated/0/Download");
    if (!await downloadDir.exists()) {
      downloadDir = await getExternalStorageDirectory();
    }

    final filePath = "${downloadDir!.path}/saarthi_health_report.pdf";
    final file = File(filePath);

    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(filePath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Your PDF has been downloaded successfully!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStatsSummary(List entries) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.green[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Statistics',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            const Text(
              'No data available for stats',
              style: TextStyle(color: Colors.grey),
            )
          else if (selectedType == 'BP')
            _buildBPStats(entries.cast<BPEntry>())
          else if (selectedType == 'CBC')
            _buildCBCStats(entries.cast<CBCEntry>())
          else
            _buildGenericStats(entries.cast<HealthMetricEntry>()),
        ],
      ),
    );
  }

  List<dynamic> _getCurrentMetricData() {
    switch (selectedType) {
      case 'Sugar':
        return _filterMetricEntries(sugarEntries);
      case 'BP':
        return _filterBPEntries();
      case 'HeartRate':
        return _filterMetricEntries(heartRateEntries);
      case 'Pulse':
        return _filterMetricEntries(pulseEntries);
      case 'Temperature':
        return _filterMetricEntries(temperatureEntries);
      case 'Weight':
        return _filterMetricEntries(weightEntries);
      case 'Height':
        return _filterMetricEntries(heightEntries);
      case 'WBC':
        return _filterMetricEntries(wbcEntries);
      case 'CBC':
        return _filterCBCEntries();
      default:
        return [];
    }
  }

  List<HealthMetricEntry> _filterMetricEntries(
    List<HealthMetricEntry> entries,
  ) {
    final now = DateTime.now();

    if (selectedMonth == 'All Time') {
      return entries;
    } else if (selectedMonth == 'Current Month') {
      return entries.where((e) {
        final date = DateTime.parse(e.date);
        return date.month == now.month && date.year == now.year;
      }).toList();
    } else {
      try {
        final selectedDate = DateFormat('MMMM yyyy').parse(selectedMonth);
        return entries.where((e) {
          final date = DateTime.parse(e.date);
          return date.month == selectedDate.month &&
              date.year == selectedDate.year;
        }).toList();
      } catch (e) {
        return [];
      }
    }
  }

  List<CBCEntry> _filterCBCEntries() {
    final now = DateTime.now();

    if (selectedMonth == 'All Time') {
      return cbcEntries;
    } else if (selectedMonth == 'Current Month') {
      return cbcEntries.where((e) {
        final date = DateTime.parse(e.date);
        return date.month == now.month && date.year == now.year;
      }).toList();
    } else {
      try {
        final selectedDate = DateFormat('MMMM yyyy').parse(selectedMonth);
        return cbcEntries.where((e) {
          final date = DateTime.parse(e.date);
          return date.month == selectedDate.month &&
              date.year == selectedDate.year;
        }).toList();
      } catch (e) {
        return [];
      }
    }
  }

  // Get current metric configuration
  Map<String, dynamic> _getCurrentMetricConfig() {
    return healthMetrics.firstWhere(
      (m) => m['type'] == selectedType,
      orElse: () => healthMetrics[0],
    );
  }

  Widget _buildGraphContainer(List entries, bool isDataEmpty) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child:
          isDataEmpty
              ? const Center(
                child: Text(
                  'No data available for this period',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : selectedType == 'BP'
              ? _buildBPGraph(entries.cast<BPEntry>())
              : selectedType == 'CBC'
              ? _buildCBCGraph(entries.cast<CBCEntry>())
              : _buildGenericGraph(entries.cast<HealthMetricEntry>()),
    );
  }

  Widget _buildCBCGraph(List<CBCEntry> entries) {
    entries.sort(
      (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)),
    );

    // Normalize values for better visualization
    // WBC: normal range 4-11 K/μL
    // RBC: normal range 4.5-5.5 M/μL
    // Hemoglobin: normal range 13-17 g/dL
    // Platelets: normal range 150-400 K/μL

    final wbcValues = entries.map((e) => e.wbc).toList();
    final rbcValues = entries.map((e) => e.rbc * 2).toList(); // Scale up RBC
    final hemoglobinValues = entries.map((e) => e.hemoglobin).toList();
    final plateletValues =
        entries.map((e) => e.platelets / 20).toList(); // Scale down platelets
    final dates = entries.map((e) => e.date).toList();

    // Find max value for scaling
    final allValues = [
      ...wbcValues,
      ...rbcValues,
      ...hemoglobinValues,
      ...plateletValues,
    ];

    final maxValue =
        allValues.isNotEmpty
            ? allValues.reduce((a, b) => a > b ? a : b) *
                1.1 // Add 10% padding
            : 20.0;

    print('CBC Graph - Max Value: $maxValue');
    print('WBC: $wbcValues');
    print('RBC (scaled): $rbcValues');
    print('Hb: $hemoglobinValues');
    print('PLT (scaled): $plateletValues');

    return GestureDetector(
      onTapDown: (details) {
        _handleCBCTap(details.localPosition, entries);
      },
      child: CustomPaint(
        painter: ImprovedCBCGraphPainter(
          wbcValues: wbcValues,
          rbcValues: rbcValues,
          // hemoglobinValues: hemoglobinValues,
          // plateletValues: plateletValues,
          dates: dates,
          maxValue: maxValue,
          selectedIndex: selectedSugarIndex,
        ),
        child: Container(),
      ),
    );
  }

  void _handleCBCTap(Offset position, List<CBCEntry> entries) {
    const double marginX = 50.0;
    final tapX = position.dx - marginX;
    final stepX =
        entries.length > 1
            ? (400 - marginX - 20) / (entries.length - 1)
            : (400 - marginX - 20) / 2;

    for (int i = 0; i < entries.length; i++) {
      final pointX = i * stepX;
      if ((tapX - pointX).abs() < 20) {
        setState(() {
          selectedSugarIndex = i;
        });
        break;
      }
    }
  }

  // Generic graph for single-value metrics
  Widget _buildGenericGraph(List<HealthMetricEntry> entries) {
    entries.sort(
      (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)),
    );

    final config = _getCurrentMetricConfig();
    final values = entries.map((e) => e.value).toList();
    final dates = entries.map((e) => e.date).toList();

    final maxValue =
        values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final minValue =
        values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0.0;

    return GestureDetector(
      onTapDown: (details) {
        _handleGenericTap(details.localPosition, entries);
      },
      child: CustomPaint(
        painter: InteractiveSugarGraphPainter(
          values: values,
          dates: dates,
          color: config['color'],
          minValue: minValue,
          maxValue: maxValue,
          selectedIndex: selectedSugarIndex,
        ),
        child: Container(),
      ),
    );
  }

  void _handleGenericTap(Offset position, List<HealthMetricEntry> entries) {
    const double marginX = 50.0;
    final tapX = position.dx - marginX;
    final stepX =
        entries.length > 1
            ? (400 - marginX - 20) / (entries.length - 1)
            : (400 - marginX - 20) / 2;

    for (int i = 0; i < entries.length; i++) {
      final pointX = i * stepX;
      if ((tapX - pointX).abs() < 20) {
        setState(() {
          selectedSugarIndex = i;
        });
        break;
      }
    }
  }

  // New generic stats builder
  Widget _buildGenericStats(List<HealthMetricEntry> entries) {
    final config = _getCurrentMetricConfig();
    final avg =
        entries.fold(0.0, (sum, entry) => sum + entry.value) / entries.length;
    final max = entries.fold(
      0.0,
      (max, entry) => entry.value > max ? entry.value : max,
    );
    final min = entries.fold(
      double.infinity,
      (min, entry) => entry.value < min ? entry.value : min,
    );

    return Column(
      children: [
        _buildStatRow('Average', '${avg.toStringAsFixed(1)} ${config['unit']}'),
        const SizedBox(height: 12),
        _buildStatRow('Highest', '${max.toStringAsFixed(1)} ${config['unit']}'),
        const SizedBox(height: 12),
        _buildStatRow('Lowest', '${min.toStringAsFixed(1)} ${config['unit']}'),
        const SizedBox(height: 12),
        _buildStatRow('Total Entries', '${entries.length}'),
      ],
    );
  }

  // New CBC stats builder
  Widget _buildCBCStats(List<CBCEntry> entries) {
    final avgWBC =
        entries.fold(0.0, (sum, entry) => sum + entry.wbc) / entries.length;
    final avgRBC =
        entries.fold(0.0, (sum, entry) => sum + entry.rbc) / entries.length;
    final avgHemoglobin =
        entries.fold(0.0, (sum, entry) => sum + entry.hemoglobin) /
        entries.length;
    final avgPlatelets =
        entries.fold(0.0, (sum, entry) => sum + entry.platelets) /
        entries.length;

    return Column(
      children: [
        _buildStatRow('Avg WBC', '${avgWBC.toStringAsFixed(1)} cells/μL'),
        const SizedBox(height: 12),
        _buildStatRow('Avg RBC', '${avgRBC.toStringAsFixed(2)} M/μL'),
        const SizedBox(height: 12),
        _buildStatRow(
          'Avg Hemoglobin',
          '${avgHemoglobin.toStringAsFixed(1)} g/dL',
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          'Avg Platelets',
          '${avgPlatelets.toStringAsFixed(0)} K/μL',
        ),
        const SizedBox(height: 12),
        _buildStatRow('Total Entries', '${entries.length}'),
      ],
    );
  }

  Widget _buildRecentEntriesList(List entries) {
    final config = _getCurrentMetricConfig();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Entries',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No entries available',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ...entries.reversed.map((entry) {
              String value;
              String date;

              if (entry is HealthEntry || entry is HealthMetricEntry) {
                final entryValue =
                    entry is HealthEntry
                        ? entry.value
                        : (entry as HealthMetricEntry).value;
                value = '${entryValue.toStringAsFixed(1)} ${config['unit']}';
                date = DateFormat(
                  'dd MMM yyyy',
                ).format(DateTime.parse(entry.date));
              } else if (entry is BPEntry) {
                value =
                    '${entry.systolic.toInt()}/${entry.diastolic.toInt()} mmHg';
                date = DateFormat(
                  'dd MMM yyyy',
                ).format(DateTime.parse(entry.date));
              } else if (entry is CBCEntry) {
                value =
                    'WBC: ${entry.wbc.toStringAsFixed(1)}, RBC: ${entry.rbc.toStringAsFixed(2)}';
                date = DateFormat(
                  'dd MMM yyyy',
                ).format(DateTime.parse(entry.date));
              } else {
                return Container();
              }
              return _buildEntryItem(value, date);
            }),
        ],
      ),
    );
  }

  // 🎯 Interactive BP Graph
  Widget _buildBPGraph(List<BPEntry> entries) {
    entries.sort(
      (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)),
    );

    final systolicValues = entries.map((e) => e.systolic).toList();
    final diastolicValues = entries.map((e) => e.diastolic).toList();
    final dates = entries.map((e) => e.date).toList();

    final maxSys =
        systolicValues.isNotEmpty
            ? systolicValues.reduce((a, b) => a > b ? a : b)
            : 0.0;
    final maxDia =
        diastolicValues.isNotEmpty
            ? diastolicValues.reduce((a, b) => a > b ? a : b)
            : 0.0;
    final maxValue =
        (maxSys > maxDia ? maxSys : maxDia) > 140
            ? (maxSys > maxDia ? maxSys : maxDia)
            : 140.0;

    return GestureDetector(
      onTapDown: (details) {
        _handleBPTap(details.localPosition, entries);
      },
      child: CustomPaint(
        painter: InteractiveBPGraphPainter(
          systolicValues,
          diastolicValues,
          dates,
          maxValue,
          Colors.red[600]!,
          Colors.blue[600]!,
          selectedBPIndex,
        ),
        child: Container(),
      ),
    );
  }

  void _handleBPTap(Offset position, List<BPEntry> entries) {
    const double marginX = 50.0;

    final tapX = position.dx - marginX;
    final stepX =
        entries.length > 1
            ? (400 - marginX - 20) / (entries.length - 1)
            : (400 - marginX - 20) / 2;

    for (int i = 0; i < entries.length; i++) {
      final pointX = i * stepX;
      if ((tapX - pointX).abs() < 20) {
        setState(() {
          selectedBPIndex = i;
        });
        break;
      }
    }
  }

  Widget _buildBPStats(List<BPEntry> entries) {
    final avgSys =
        entries.fold(0.0, (sum, entry) => sum + entry.systolic) /
        entries.length;
    final avgDia =
        entries.fold(0.0, (sum, entry) => sum + entry.diastolic) /
        entries.length;
    final maxSys = entries.fold(
      0.0,
      (max, entry) => entry.systolic > max ? entry.systolic : max,
    );
    final minSys = entries.fold(
      double.infinity,
      (min, entry) => entry.systolic < min ? entry.systolic : min,
    );

    return Column(
      children: [
        _buildStatRow('Avg Systolic', '${avgSys.toStringAsFixed(0)} mmHg'),
        const SizedBox(height: 12),
        _buildStatRow('Avg Diastolic', '${avgDia.toStringAsFixed(0)} mmHg'),
        const SizedBox(height: 12),
        _buildStatRow('Highest Sys', '${maxSys.toStringAsFixed(0)} mmHg'),
        const SizedBox(height: 12),
        _buildStatRow('Lowest Sys', '${minSys.toStringAsFixed(0)} mmHg'),
        const SizedBox(height: 12),
        _buildStatRow('Total Entries', '${entries.length}'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEntryItem(String value, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              // overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 10),
          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

class InteractiveSugarGraphPainter extends CustomPainter {
  final List<double> values;
  final List<String> dates;
  final Color color;
  final double minValue;
  final double maxValue;
  final int? selectedIndex;

  InteractiveSugarGraphPainter({
    required this.values,
    required this.dates,
    required this.color,
    required this.minValue,
    required this.maxValue,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const double marginX = 50.0;
    const double marginBottom = 50.0;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final range =
        (maxValue - minValue) > 5
            ? (maxValue - minValue)
            : (maxValue > 0 ? maxValue * 0.2 : 100);
    final baseline = minValue < 10 ? 0.0 : minValue;

    final effectiveWidth = size.width - marginX;
    final effectiveHeight = size.height - marginBottom;
    final stepX =
        values.length > 1
            ? effectiveWidth / (values.length - 1)
            : effectiveWidth / 2;

    // Draw Y-Axis labels
    final yLabels = [maxValue, (maxValue + minValue) / 2, minValue];
    for (int i = 0; i < yLabels.length; i++) {
      final value = yLabels[i];
      final yPos =
          effectiveHeight -
          ((value - baseline) / range) * (effectiveHeight - 20);

      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(5, yPos - textPainter.height / 2));

      final gridPaint =
          Paint()
            ..color = Colors.grey.withOpacity(0.3)
            ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(marginX, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
    }

    final path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < values.length; i++) {
      final x = (i * stepX) + marginX;
      final normalizedValue = (values[i] - baseline) / range;
      final y = effectiveHeight - (normalizedValue * (effectiveHeight - 20));

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw points
      final isSelected = i == selectedIndex;
      canvas.drawCircle(Offset(x, y), isSelected ? 8 : 5, pointPaint);

      // Draw date labels
      final date = DateTime.parse(dates[i]);
      final dateLabel = DateFormat('dd/MM').format(date);

      final dateTextPainter = TextPainter(
        text: TextSpan(
          text: dateLabel,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      dateTextPainter.layout();

      canvas.save();
      canvas.translate(x, effectiveHeight + 10);
      if (values.length > 10) {
        canvas.rotate(-0.5);
      }
      dateTextPainter.paint(canvas, Offset(-dateTextPainter.width / 2, 0));
      canvas.restore();
    }

    if (values.length > 1) {
      canvas.drawPath(path, paint);
    }

    // 🎯 Draw Tooltip for Selected Point
    if (selectedIndex != null && selectedIndex! < values.length) {
      final selectedPoint = points[selectedIndex!];

      // Draw vertical line
      final linePaint =
          Paint()
            ..color = color.withOpacity(0.5)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(selectedPoint.dx, marginX),
        Offset(selectedPoint.dx, effectiveHeight),
        linePaint,
      );

      // Draw tooltip
      final value = values[selectedIndex!];
      final date = DateTime.parse(dates[selectedIndex!]);
      final dateStr = DateFormat('dd MMM yyyy').format(date);
      final valueStr = '${value.toStringAsFixed(1)} mg/dL';

      final tooltipText = '$valueStr\n$dateStr';
      final tooltipPainter = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tooltipPainter.layout();

      final tooltipWidth = tooltipPainter.width + 20;
      final tooltipHeight = tooltipPainter.height + 16;

      double tooltipX = selectedPoint.dx - tooltipWidth / 2;
      double tooltipY = selectedPoint.dy - tooltipHeight - 15;

      // Adjust if tooltip goes out of bounds
      if (tooltipX < 0) tooltipX = 5;
      if (tooltipX + tooltipWidth > size.width)
        tooltipX = size.width - tooltipWidth - 5;
      if (tooltipY < 0) tooltipY = selectedPoint.dy + 15;

      // Draw tooltip background
      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(8),
      );

      final tooltipBgPaint =
          Paint()
            ..color = color.withOpacity(0.95)
            ..style = PaintingStyle.fill;
      canvas.drawRRect(tooltipRect, tooltipBgPaint);

      // Draw tooltip shadow
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(tooltipRect, shadowPaint);

      // Draw tooltip text
      tooltipPainter.paint(canvas, Offset(tooltipX + 10, tooltipY + 8));
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveSugarGraphPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.dates != dates ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

// 🎯 Interactive BP Graph Painter with Tooltip
class InteractiveBPGraphPainter extends CustomPainter {
  final List<double> systolicValues;
  final List<double> diastolicValues;
  final List<String> dates;
  final double maxValue;
  final Color systolicColor;
  final Color diastolicColor;
  final int? selectedIndex;

  InteractiveBPGraphPainter(
    this.systolicValues,
    this.diastolicValues,
    this.dates,
    this.maxValue,
    this.systolicColor,
    this.diastolicColor,
    this.selectedIndex,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (systolicValues.isEmpty) return;

    const double marginX = 50.0;
    const double marginBottom = 50.0;

    final systolicPaint =
        Paint()
          ..color = systolicColor
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final diastolicPaint =
        Paint()
          ..color = diastolicColor
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final systolicPath = Path();
    final diastolicPath = Path();

    final pointPaintSys =
        Paint()
          ..color = systolicColor
          ..style = PaintingStyle.fill;
    final pointPaintDia =
        Paint()
          ..color = diastolicColor
          ..style = PaintingStyle.fill;

    final effectiveWidth = size.width - marginX;
    final effectiveHeight = size.height - marginBottom;
    final stepX =
        systolicValues.length > 1
            ? effectiveWidth / (systolicValues.length - 1)
            : effectiveWidth / 2;

    // Draw Y-axis labels and grid
    final yLabels = [maxValue, 120.0, 80.0, 60.0];
    for (final value in yLabels) {
      if (value < 0 || value > maxValue) continue;

      final yPos =
          effectiveHeight - (value / maxValue) * (effectiveHeight - 20);
      if (yPos < 10 || yPos > effectiveHeight) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(5, yPos - textPainter.height / 2));

      final gridPaint =
          Paint()
            ..color = Colors.grey.withOpacity(0.3)
            ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(marginX, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
    }

    final List<Offset> sysPoints = [];
    final List<Offset> diaPoints = [];

    // Draw points and paths
    for (int i = 0; i < systolicValues.length; i++) {
      final x = (i * stepX) + marginX;

      final ySys =
          effectiveHeight -
          (systolicValues[i] / maxValue) * (effectiveHeight - 20);
      final yDia =
          effectiveHeight -
          (diastolicValues[i] / maxValue) * (effectiveHeight - 20);

      sysPoints.add(Offset(x, ySys));
      diaPoints.add(Offset(x, yDia));

      if (i == 0) {
        systolicPath.moveTo(x, ySys);
        diastolicPath.moveTo(x, yDia);
      } else {
        systolicPath.lineTo(x, ySys);
        diastolicPath.lineTo(x, yDia);
      }

      final isSelected = i == selectedIndex;
      canvas.drawCircle(Offset(x, ySys), isSelected ? 8 : 5, pointPaintSys);
      canvas.drawCircle(Offset(x, yDia), isSelected ? 8 : 5, pointPaintDia);

      // Draw X-axis date label
      final date = DateTime.parse(dates[i]);
      final dateLabel = DateFormat('dd/MM').format(date);

      final dateTextPainter = TextPainter(
        text: TextSpan(
          text: dateLabel,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      dateTextPainter.layout();

      canvas.save();
      canvas.translate(x, effectiveHeight + 10);
      if (systolicValues.length > 10) {
        canvas.rotate(-0.5);
      }
      dateTextPainter.paint(canvas, Offset(-dateTextPainter.width / 2, 0));
      canvas.restore();
    }

    if (systolicValues.length > 1) {
      canvas.drawPath(systolicPath, systolicPaint);
      canvas.drawPath(diastolicPath, diastolicPaint);
    }

    // 🎯 Draw Tooltip for Selected Point
    if (selectedIndex != null && selectedIndex! < systolicValues.length) {
      final x = (selectedIndex! * stepX) + marginX;

      // Draw vertical line
      final linePaint =
          Paint()
            ..color = Colors.grey.withOpacity(0.6)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, 30), Offset(x, effectiveHeight), linePaint);

      // Draw tooltip
      final sysValue = systolicValues[selectedIndex!];
      final diaValue = diastolicValues[selectedIndex!];
      final date = DateTime.parse(dates[selectedIndex!]);
      final dateStr = DateFormat('dd MMM yyyy').format(date);

      final tooltipText =
          'Systolic: ${sysValue.toInt()} mmHg\nDiastolic: ${diaValue.toInt()} mmHg\n$dateStr';
      final tooltipPainter = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tooltipPainter.layout();

      final tooltipWidth = tooltipPainter.width + 20;
      final tooltipHeight = tooltipPainter.height + 16;

      double tooltipX = x - tooltipWidth / 2;
      double tooltipY = 40;

      // Adjust if tooltip goes out of bounds
      if (tooltipX < 0) tooltipX = 5;
      if (tooltipX + tooltipWidth > size.width)
        tooltipX = size.width - tooltipWidth - 5;

      // Draw tooltip background
      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(8),
      );

      final tooltipBgPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.85)
            ..style = PaintingStyle.fill;
      canvas.drawRRect(tooltipRect, tooltipBgPaint);

      // Draw tooltip shadow
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(tooltipRect, shadowPaint);

      // Draw tooltip text
      tooltipPainter.paint(canvas, Offset(tooltipX + 10, tooltipY + 8));

      // Draw colored indicators
      final sysIndicator =
          Paint()
            ..color = systolicColor
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tooltipX + 8, tooltipY + 16), 4, sysIndicator);

      final diaIndicator =
          Paint()
            ..color = diastolicColor
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tooltipX + 8, tooltipY + 32), 4, diaIndicator);
    }

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawLegend(Canvas canvas, Size size) {
    const legendY = 10.0;
    const legendX = 60.0;

    // Systolic legend
    final sysPaint =
        Paint()
          ..color = systolicColor
          ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(legendX, legendY), 5, sysPaint);

    final sysTextPainter = TextPainter(
      text: TextSpan(
        text: 'Systolic',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    sysTextPainter.layout();
    sysTextPainter.paint(canvas, const Offset(legendX + 10, legendY - 6));

    // Diastolic legend
    final diaPaint =
        Paint()
          ..color = diastolicColor
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(legendX + sysTextPainter.width + 30, legendY),
      5,
      diaPaint,
    );

    final diaTextPainter = TextPainter(
      text: TextSpan(
        text: 'Diastolic',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    diaTextPainter.layout();
    diaTextPainter.paint(
      canvas,
      Offset(legendX + sysTextPainter.width + 40, legendY - 6),
    );
  }

  @override
  bool shouldRepaint(covariant InteractiveBPGraphPainter oldDelegate) {
    return oldDelegate.systolicValues != systolicValues ||
        oldDelegate.diastolicValues != diastolicValues ||
        oldDelegate.dates != dates ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class HealthEntry {
  final String id;
  final double value;
  final String date;
  final int? timestamp;
  final String? timeOfDay;
  final String mealTime;

  HealthEntry({
    required this.id,
    required this.value,
    required this.date,
    this.timestamp,
    this.timeOfDay,
    required this.mealTime,
  });
}

class BPEntry {
  final String id;
  final double systolic;
  final double diastolic;
  final String date;
  final int? timestamp;
  final String? timeOfDay;

  BPEntry({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.date,
    this.timestamp,
    this.timeOfDay,
  });
}

class NoteEntry {
  final String id;
  final String text;
  final String date;
  final int? timestamp;

  NoteEntry({
    required this.id,
    required this.text,
    required this.date,
    this.timestamp,
  });
}

class HealthMetricEntry {
  final String id;
  final double value;
  final String date;
  final int? timestamp;
  final String? timeOfDay;
  final String? mealTime;

  HealthMetricEntry({
    required this.id,
    required this.value,
    required this.date,
    this.timestamp,
    this.timeOfDay,
    this.mealTime,
  });
}

class CBCEntry {
  final String id;
  final double rbc;
  final double wbc;
  final double hemoglobin;
  final double platelets;
  final String date;
  final int? timestamp;
  final String? timeOfDay;

  CBCEntry({
    required this.id,
    required this.rbc,
    required this.wbc,
    required this.hemoglobin,
    required this.platelets,
    required this.date,
    this.timestamp,
    this.timeOfDay,
  });
}

// CBC Graph Painter with WBC and RBC only
class ImprovedCBCGraphPainter extends CustomPainter {
  final List<double> wbcValues;
  final List<double> rbcValues;
  final List<String> dates;
  final double maxValue;
  final int? selectedIndex;

  ImprovedCBCGraphPainter({
    required this.wbcValues,
    required this.rbcValues,
    required this.dates,
    required this.maxValue,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wbcValues.isEmpty) return;

    const double marginX = 50.0;
    const double marginBottom = 60.0;
    const double marginTop = 40.0;

    final effectiveWidth = size.width - marginX - 20;
    final effectiveHeight = size.height - marginBottom - marginTop;
    final stepX =
        wbcValues.length > 1
            ? effectiveWidth / (wbcValues.length - 1)
            : effectiveWidth / 2;

    // Draw Y-axis labels and grid
    final yLabels = [
      maxValue,
      maxValue * 0.75,
      maxValue * 0.5,
      maxValue * 0.25,
      0.0,
    ];
    for (final value in yLabels) {
      final yPos =
          marginTop + effectiveHeight - (value / maxValue) * effectiveHeight;

      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(5, yPos - textPainter.height / 2));

      final gridPaint =
          Paint()
            ..color = Colors.grey.withOpacity(0.2)
            ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(marginX, yPos),
        Offset(size.width - 10, yPos),
        gridPaint,
      );
    }

    // Draw lines and points for WBC and RBC only
    _drawComponent(
      canvas,
      wbcValues,
      marginX,
      marginTop,
      effectiveHeight,
      stepX,
      Colors.red,
      'WBC',
    );
    _drawComponent(
      canvas,
      rbcValues,
      marginX,
      marginTop,
      effectiveHeight,
      stepX,
      Colors.blue,
      'RBC',
    );

    // Draw date labels
    for (int i = 0; i < dates.length; i++) {
      final x = (i * stepX) + marginX;
      final date = DateTime.parse(dates[i]);
      final dateLabel = DateFormat('dd/MM').format(date);

      final dateTextPainter = TextPainter(
        text: TextSpan(
          text: dateLabel,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      dateTextPainter.layout();

      canvas.save();
      canvas.translate(x, marginTop + effectiveHeight + 10);
      if (dates.length > 10) {
        canvas.rotate(-0.5);
      }
      dateTextPainter.paint(canvas, Offset(-dateTextPainter.width / 2, 0));
      canvas.restore();
    }

    // Draw tooltip if selected
    if (selectedIndex != null && selectedIndex! < wbcValues.length) {
      _drawTooltip(canvas, size, marginX, marginTop, effectiveHeight, stepX);
    }

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawComponent(
    Canvas canvas,
    List<double> values,
    double marginX,
    double marginTop,
    double effectiveHeight,
    double stepX,
    Color color,
    String label,
  ) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = (i * stepX) + marginX;
      final y =
          marginTop +
          effectiveHeight -
          (values[i] / maxValue) * effectiveHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      final isSelected = i == selectedIndex;
      final pointSize = isSelected ? 6.0 : 3.5;
      canvas.drawCircle(Offset(x, y), pointSize, pointPaint);
    }

    // Draw line
    if (values.length > 1) {
      canvas.drawPath(path, paint);
    }
  }

  void _drawTooltip(
    Canvas canvas,
    Size size,
    double marginX,
    double marginTop,
    double effectiveHeight,
    double stepX,
  ) {
    final x = (selectedIndex! * stepX) + marginX;

    // Draw vertical line
    final linePaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(x, marginTop),
      Offset(x, marginTop + effectiveHeight),
      linePaint,
    );

    // Create tooltip text with WBC and RBC only
    final date = DateTime.parse(dates[selectedIndex!]);
    final dateStr = DateFormat('dd MMM yyyy').format(date);

    final tooltipText =
        'WBC: ${wbcValues[selectedIndex!].toStringAsFixed(1)} cells/μL\n'
        'RBC: ${rbcValues[selectedIndex!].toStringAsFixed(2)} M/μL\n'
        '$dateStr';

    final tooltipPainter = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    tooltipPainter.layout();

    final tooltipWidth = tooltipPainter.width + 20;
    final tooltipHeight = tooltipPainter.height + 16;

    double tooltipX = x - tooltipWidth / 2;
    double tooltipY = marginTop + 5;

    if (tooltipX < 0) tooltipX = 5;
    if (tooltipX + tooltipWidth > size.width) {
      tooltipX = size.width - tooltipWidth - 5;
    }

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(8),
    );

    final tooltipBgPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.85)
          ..style = PaintingStyle.fill;
    canvas.drawRRect(tooltipRect, tooltipBgPaint);

    tooltipPainter.paint(canvas, Offset(tooltipX + 10, tooltipY + 8));
  }

  void _drawLegend(Canvas canvas, Size size) {
    const legendY = 15.0;
    const legendX = 100.0;
    const spacing = 80.0;

    final legends = [
      {'label': 'WBC', 'color': Colors.red},
      {'label': 'RBC', 'color': Colors.blue},
    ];

    for (int i = 0; i < legends.length; i++) {
      final x = legendX + (i * spacing);
      final legend = legends[i];

      final paint =
          Paint()
            ..color = legend['color'] as Color
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, legendY), 4, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: legend['label'] as String,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 8, legendY - 5));
    }
  }

  @override
  bool shouldRepaint(covariant ImprovedCBCGraphPainter oldDelegate) {
    return oldDelegate.wbcValues != wbcValues ||
        oldDelegate.rbcValues != rbcValues ||
        oldDelegate.dates != dates ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
