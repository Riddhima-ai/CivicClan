import 'dart:convert';
import 'helpline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'services/FirestoreService.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------
class StateIssueData {
  final String stateName;
  final int openIssues;
  final int resolvedIssues;

  StateIssueData({
    required this.stateName,
    required this.openIssues,
    required this.resolvedIssues,
  });

  double get healthScore {
    final total = openIssues + resolvedIssues;
    if (total == 0) return 1.0;
    return resolvedIssues / total;
  }

  Color get stateColor {
    final total = openIssues + resolvedIssues;
    if (total == 0) return const Color(0xFF22C55E);
    if (healthScore >= 0.65) return const Color(0xFF22C55E);
    if (healthScore >= 0.35) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class IndiaCivicDashboard_realtime extends StatefulWidget {
  const IndiaCivicDashboard_realtime({super.key});

  @override
  State<IndiaCivicDashboard_realtime> createState() =>
      _IndiaCivicDashboardState();
}

class _IndiaCivicDashboardState extends State<IndiaCivicDashboard_realtime> {
  final FirestoreService firestoreService = FirestoreService();

  int _selectedIndex = -1;

  /// Actual NAME_1 values extracted from the GeoJSON at runtime.
  /// Populated by [_loadGeoJsonNames]. Empty until then.
  List<String> _geoJsonNames = [];

  /// Set to true once [_loadGeoJsonNames] finishes.
  bool _namesLoaded = false;

  // ── canonical display names used throughout the UI ──────────────────────
  //
  // These are the names you want to show in tooltips / Firestore keys.
  // They are mapped → actual GeoJSON NAME_1 values via [_displayToGeoJson].
  //
  static const List<String> _displayNames = [
    "Andaman and Nicobar",
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chandigarh",
    "Chhattisgarh",
    "Dadra and Nagar Haveli",
    "Daman and Diu",
    "Delhi",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jammu and Kashmir",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Lakshadweep",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Puducherry",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
  ];

  // ── known variant spellings in various GADM / natural-earth GeoJSON files ─
  //
  // Key   = canonical display name (used in Firestore / UI)
  // Value = ordered list of GeoJSON NAME_1 candidates to try, most-likely first
  //
  static const Map<String, List<String>> _variantMap = {
    "Andaman and Nicobar": [
      "Andaman and Nicobar",
      "Andaman & Nicobar",
      "Andaman & Nicobar Islands",
      "Andaman and Nicobar Islands",
    ],
    "Dadra and Nagar Haveli": [
      "Dadra and Nagar Haveli",
      "Dadra & Nagar Haveli",
      "Dadra and Nagar Haveli and Daman and Diu",
    ],
    "Daman and Diu": [
      "Daman and Diu",
      "Daman & Diu",
      // merged UT in some post-2020 files:
      "Dadra and Nagar Haveli and Daman and Diu",
    ],
    "Jammu and Kashmir": ["Jammu and Kashmir", "Jammu & Kashmir"],
    "Odisha": ["Odisha", "Orissa"],
    "Puducherry": ["Puducherry", "Pondicherry"],
    "Uttarakhand": ["Uttarakhand", "Uttaranchal"],
    // Telangana was carved out of Andhra Pradesh in 2014.
    // Pre-2014 GeoJSON files won't have it at all.
    "Telangana": ["Telangana"],
    // Some GADM builds use "NCT of Delhi"
    "Delhi": ["Delhi", "NCT of Delhi", "National Capital Territory of Delhi"],
  };

  // ── resolved at runtime after GeoJSON is parsed ─────────────────────────
  //
  // Maps displayName → the NAME_1 string that actually exists in the GeoJSON.
  // Built once by [_resolveNames].
  //
  Map<String, String> _displayToGeoJson = {};

  // ── lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadGeoJsonNames();
  }

  /// Reads the GeoJSON asset, collects every unique NAME_1 value, then calls
  /// [_resolveNames] to build the display→geoJson mapping.
  Future<void> _loadGeoJsonNames() async {
    try {
      final raw = await rootBundle.loadString('assets/maps/india.json');
      final Map<String, dynamic> json = jsonDecode(raw);
      final features = (json['features'] as List?) ?? [];

      final names = <String>{};
      for (final f in features) {
        final name = f['properties']?['NAME_1'];
        if (name is String && name.isNotEmpty) names.add(name);
      }

      final sorted = names.toList()..sort();

      // ── DEBUG: prints every GeoJSON NAME_1 to the console ──
      debugPrint('═══════════════════════════════════════');
      debugPrint('GeoJSON NAME_1 values (${sorted.length} total):');
      for (final n in sorted) {
        debugPrint('  "$n"');
      }
      debugPrint('═══════════════════════════════════════');

      if (!mounted) return;
      setState(() {
        _geoJsonNames = sorted;
        _displayToGeoJson = _resolveNames(sorted);
        _namesLoaded = true;
      });

      _printMismatches(); // logs any unresolved names
    } catch (e) {
      debugPrint('Failed to load GeoJSON names: $e');
      if (!mounted) return;
      // Fall back: use display names directly so the map still renders
      setState(() {
        _displayToGeoJson = {for (final n in _displayNames) n: n};
        _namesLoaded = true;
      });
    }
  }

  /// For each display name, find the first matching GeoJSON NAME_1 value.
  /// Priority order:
  ///   1. exact match in geoJsonNames
  ///   2. variant from [_variantMap] that exists in geoJsonNames
  ///   3. case-insensitive match
  ///   4. fall back to the display name itself (will show grey — flagged in
  ///      [_printMismatches])
  Map<String, String> _resolveNames(List<String> geoJsonNames) {
    final geoSet = geoJsonNames.toSet();
    final geoLower = {for (final n in geoJsonNames) n.toLowerCase(): n};
    final result = <String, String>{};

    for (final display in _displayNames) {
      // 1. exact
      if (geoSet.contains(display)) {
        result[display] = display;
        continue;
      }

      // 2. known variants
      final variants = _variantMap[display] ?? [];
      String? found;
      for (final v in variants) {
        if (geoSet.contains(v)) {
          found = v;
          break;
        }
      }
      if (found != null) {
        result[display] = found;
        continue;
      }

      // 3. case-insensitive
      final ci = geoLower[display.toLowerCase()];
      if (ci != null) {
        result[display] = ci;
        continue;
      }

      // 4. unresolved — will render grey
      result[display] = display;
    }

    return result;
  }

  /// Prints any display names that could not be resolved to a GeoJSON name.
  void _printMismatches() {
    final geoSet = _geoJsonNames.toSet();
    final unresolved = <String>[];
    for (final display in _displayNames) {
      final mapped = _displayToGeoJson[display];
      if (mapped != null && !geoSet.contains(mapped)) {
        unresolved.add(display);
      }
    }

    if (unresolved.isEmpty) {
      debugPrint('✅ All state names resolved successfully.');
    } else {
      debugPrint('⚠️  Unresolved state names (will render grey):');
      for (final n in unresolved) {
        debugPrint('  "$n"  →  "${_displayToGeoJson[n]}"  (not in GeoJSON)');
      }
      debugPrint(
        'Fix: add the correct GeoJSON spelling to _variantMap for each entry above.',
      );
    }
  }

  // ── data helpers ─────────────────────────────────────────────────────────

  List<StateIssueData> _buildDataSource(Map<String, Map<String, int>> raw) {
    final open = raw['open'] ?? {};
    final resolved = raw['resolved'] ?? {};

    return _displayNames.map((display) {
      // Look up Firestore data by display name
      return StateIssueData(
        stateName: _displayToGeoJson[display] ?? display,
        openIssues: open[display] ?? 0,
        resolvedIssues: resolved[display] ?? 0,
      );
    }).toList();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_namesLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF07111D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "🇮🇳 National Civic Pulse",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // ── debug button (remove before release) ──
        actions: [
          IconButton(
            tooltip: 'Print GeoJSON name debug info',
            icon: const Icon(Icons.bug_report_outlined, color: Colors.white38),
            onPressed: _printMismatches,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, Map<String, int>>>(
        stream: firestoreService.streamStateIssueCounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final raw = snapshot.data ?? {'open': {}, 'resolved': {}};
          final dataSource = _buildDataSource(raw);

          final totalOpen = dataSource.fold(0, (s, d) => s + d.openIssues);
          final totalResolved = dataSource.fold(
            0,
            (s, d) => s + d.resolvedIssues,
          );

          return Column(
            children: [
              const SizedBox(height: 10),

              // ── summary cards ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        "$totalOpen",
                        "Open Issues",
                        const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCard(
                        "$totalResolved",
                        "Resolved",
                        const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── state detail tooltip ───────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child:
                    _selectedIndex >= 0 && _selectedIndex < dataSource.length
                        ? _buildStateTooltip(
                          dataSource[_selectedIndex],
                          // Show the user-friendly display name, not the raw GeoJSON name
                          _displayNames[_selectedIndex],
                        )
                        : const SizedBox(
                          height: 44,
                          child: Center(
                            child: Text(
                              "Tap a state to see details",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
              ),

              const SizedBox(height: 4),

              // ── map ────────────────────────────────────────────────────
              Expanded(
                child: SfMaps(
                  layers: [
                    MapShapeLayer(
                      source: MapShapeSource.asset(
                        'assets/maps/india.json',
                        shapeDataField: "NAME_1",
                        dataCount: dataSource.length,
                        // primaryValueMapper returns the GeoJSON NAME_1 value
                        // so it matches the shapeDataField correctly.
                        primaryValueMapper: (i) => dataSource[i].stateName,
                        shapeColorValueMapper: (i) => dataSource[i].stateColor,
                      ),
                      strokeColor: Colors.white24,
                      strokeWidth: 0.8,
                      selectedIndex: _selectedIndex,
                      onSelectionChanged: (index) {
                        setState(() {
                          _selectedIndex = _selectedIndex == index ? -1 : index;
                        });
                      },
                      selectionSettings: const MapSelectionSettings(
                        color: Colors.white24,
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // ── legend ─────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _legendItem(
                      const Color(0xFF22C55E),
                      "Low Issues",
                      "≥65% resolved",
                    ),
                    _legendItem(
                      const Color(0xFFF59E0B),
                      "Medium",
                      "35–65% resolved",
                    ),
                    _legendItem(
                      const Color(0xFFEF4444),
                      "High Issues",
                      "<35% resolved",
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildStateTooltip(StateIssueData data, String displayName) {
    return Container(
      key: ValueKey(displayName),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.stateColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.stateColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _statChip(
                Icons.warning_amber_rounded,
                "${data.openIssues} open",
                const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              _statChip(
                Icons.check_circle_outline,
                "${data.resolvedIssues} resolved",
                const Color(0xFF22C55E),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text("View Helpline Numbers"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelplinePage(stateName: displayName),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String title, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

// Dart doesn't have a built-in discard operator; this silences the
// unused-variable lint for `healthColor` until you wire it into the UI.
extension on Object? {
  // ignore: unused_element
  void get _ {}
}
