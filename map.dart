import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'helpline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'services/FirestoreService.dart';

// ---------------------------------------------------------------------------
// Palette — "Luxury Dark Analytics" theme
// ---------------------------------------------------------------------------
class _Palette {
  static const bgDeep = Color(0xFF020617);
  static const bgMid = Color(0xFF07111D);
  static const bgSurfaceTint = Color(0xFF0B1220);

  static const glassFill = Color(0x0DFFFFFF); // 5% white
  static const glassFillStrong = Color(0x14FFFFFF); // 8% white
  static const glassBorder = Color(0x14FFFFFF); // 8% white

  static const primary = Color(0xFF2563EB);
  static const accent = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const gold = Color(0xFFD4AF37);
  static const purple = Color(0xFF8B5CF6);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);
}

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

  /// Premium color tiers. Thresholds are UNCHANGED from the original
  /// algorithm — only the hex values were upgraded to the new palette.
  Color get stateColor {
    final total = openIssues + resolvedIssues;
    if (total == 0) return _Palette.success;
    if (healthScore >= 0.65) return _Palette.success;
    if (healthScore >= 0.35) return _Palette.warning;
    return _Palette.danger;
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

class _IndiaCivicDashboardState extends State<IndiaCivicDashboard_realtime>
    with SingleTickerProviderStateMixin {
  final FirestoreService firestoreService = FirestoreService();

  int _selectedIndex = -1;

  /// Actual NAME_1 values extracted from the GeoJSON at runtime.
  /// Populated by [_loadGeoJsonNames]. Empty until then.
  List<String> _geoJsonNames = [];

  /// Set to true once [_loadGeoJsonNames] finishes.
  bool _namesLoaded = false;

  // pulse animation driving the LIVE indicator + map glow
  late final AnimationController _pulseController;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadGeoJsonNames();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      return Scaffold(
        backgroundColor: _Palette.bgMid,
        body: _PremiumShell(
          pulse: _pulseController,
          onBack: () => Navigator.pop(context),
          child: const Center(
            child: CircularProgressIndicator(color: _Palette.purple),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _Palette.bgMid,
      body: StreamBuilder<Map<String, Map<String, int>>>(
        stream: firestoreService.streamStateIssueCounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _PremiumShell(
              pulse: _pulseController,
              onBack: () => Navigator.pop(context),
              child: const Center(
                child: CircularProgressIndicator(color: _Palette.purple),
              ),
            );
          }

          if (snapshot.hasError) {
            return _PremiumShell(
              pulse: _pulseController,
              onBack: () => Navigator.pop(context),
              child: Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: _Palette.danger),
                ),
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
          final totalAll = totalOpen + totalResolved;
          final responseRate =
              totalAll == 0 ? 0.0 : (totalResolved / totalAll) * 100;
          final activeStates =
              dataSource
                  .where((d) => (d.openIssues + d.resolvedIssues) > 0)
                  .length;
          final totalStates = dataSource.length;

          return _PremiumShell(
            pulse: _pulseController,
            onBack: () => Navigator.pop(context),
            child: Column(
              children: [
                const SizedBox(height: 4),

                // ── hero metrics ─────────────────────────────────────────
                _HeroMetricsRow(
                  openIssues: totalOpen,
                  resolvedIssues: totalResolved,
                  responseRate: responseRate,
                  activeStates: activeStates,
                  totalStates: totalStates,
                ),

                const SizedBox(height: 12),

                // ── selected-state quick view ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child:
                        (_selectedIndex >= 0 &&
                                _selectedIndex < dataSource.length)
                            ? _SelectedStateBar(
                              key: ValueKey(_selectedIndex),
                              data: dataSource[_selectedIndex],
                              displayName: _displayNames[_selectedIndex],
                              onViewDetails: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => HelplinePage(
                                          stateName:
                                              _displayNames[_selectedIndex],
                                        ),
                                  ),
                                );
                              },
                              onClose:
                                  () => setState(() => _selectedIndex = -1),
                            )
                            : const _SelectedStateHint(),
                  ),
                ),

                const SizedBox(height: 10),

                // ── map ───────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MapGlassPanel(
                      pulse: _pulseController,
                      child: SfMaps(
                        layers: [
                          MapShapeLayer(
                            source: MapShapeSource.asset(
                              'assets/maps/india.json',
                              shapeDataField: "NAME_1",
                              dataCount: dataSource.length,
                              // primaryValueMapper returns the GeoJSON NAME_1 value
                              // so it matches the shapeDataField correctly.
                              primaryValueMapper:
                                  (i) => dataSource[i].stateName,
                              shapeColorValueMapper:
                                  (i) => dataSource[i].stateColor,
                            ),
                            strokeColor: Colors.white24,
                            strokeWidth: 0.8,
                            selectedIndex: _selectedIndex,
                            onSelectionChanged: (index) {
                              setState(() {
                                _selectedIndex =
                                    _selectedIndex == index ? -1 : index;
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
                  ),
                ),

                const SizedBox(height: 12),

                // ── floating analytics panel (legend) ───────────────────
                _AnalyticsPanel(dataSource: dataSource),

                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── state details bottom sheet ─────────────────────────────────────────

  void _showStateDetailsSheet(
    BuildContext context,
    StateIssueData data,
    String displayName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => _StateDetailsSheet(data: data, displayName: displayName),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared "glass" container
// ---------------------------------------------------------------------------
class _Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final Color? fillColor;
  final BorderRadius? customRadius;

  const _Glass({
    required this.child,
    this.radius = 20,
    this.padding,
    this.borderColor,
    this.shadow,
    this.fillColor,
    this.customRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final br = customRadius ?? BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(borderRadius: br, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor ?? _Palette.glassFill,
              borderRadius: br,
              border: Border.all(color: borderColor ?? _Palette.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium shell: background + floating app bar + content
// ---------------------------------------------------------------------------
class _PremiumShell extends StatelessWidget {
  final AnimationController pulse;
  final VoidCallback onBack;
  final Widget child;

  const _PremiumShell({
    required this.pulse,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _BackgroundLayer()),
        SafeArea(
          child: Column(
            children: [
              _FloatingAppBar(pulse: pulse, onBack: onBack),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Background — gradient mesh + faint starfield
// ---------------------------------------------------------------------------
class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.3,
          colors: [_Palette.bgSurfaceTint, _Palette.bgMid, _Palette.bgDeep],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _StarFieldPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  // fixed seed → identical, lightweight "stars" every frame (no re-randomizing)
  static final List<Offset> _seeds = List.generate(60, (i) {
    final r = Random(i * 97 + 13);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    for (final s in _seeds) {
      final dx = s.dx * size.width;
      final dy = s.dy * size.height;
      final radius = (s.dx * 1.6) % 1.4 + 0.4;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }

    // a couple of soft blue glows
    final glow1 =
        Paint()
          ..color = _Palette.accent.withOpacity(0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.15), 140, glow1);

    final glow2 =
        Paint()
          ..color = _Palette.purple.withOpacity(0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.65),
      160,
      glow2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Floating glass app bar
// ---------------------------------------------------------------------------
class _FloatingAppBar extends StatelessWidget {
  final AnimationController pulse;
  final VoidCallback onBack;

  const _FloatingAppBar({required this.pulse, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: _Glass(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            _CircleIconButton(icon: Icons.arrow_back_ios_new, onTap: onBack),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "🇮🇳  National Civic Pulse",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _Palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Real-time India Civic Intelligence",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _Palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _LiveIndicator(pulse: pulse),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  final AnimationController pulse;

  const _LiveIndicator({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = 0.25 + (0.55 * pulse.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _Palette.success.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Palette.success.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Palette.success,
                  boxShadow: [
                    BoxShadow(
                      color: _Palette.success.withOpacity(glow),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "LIVE",
                style: TextStyle(
                  color: _Palette.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero metric cards
// ---------------------------------------------------------------------------
class _HeroMetricsRow extends StatelessWidget {
  final int openIssues;
  final int resolvedIssues;
  final double responseRate;
  final int activeStates;
  final int totalStates;

  const _HeroMetricsRow({
    required this.openIssues,
    required this.resolvedIssues,
    required this.responseRate,
    required this.activeStates,
    required this.totalStates,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        icon: Icons.warning_amber_rounded,
        color: _Palette.danger,
        label: "Open Issues",
        valueWidget: _AnimatedNumber(value: openIssues.toDouble()),
      ),
      _MetricCard(
        icon: Icons.check_circle_outline,
        color: _Palette.success,
        label: "Resolved",
        valueWidget: _AnimatedNumber(value: resolvedIssues.toDouble()),
      ),
      _MetricCard(
        icon: Icons.schedule_rounded,
        color: _Palette.accent,
        label: "Response Rate",
        valueWidget: _AnimatedNumber(
          value: responseRate,
          decimals: 1,
          suffix: "%",
        ),
      ),
      _MetricCard(
        icon: Icons.account_balance_outlined,
        color: _Palette.purple,
        label: "Active States",
        valueWidget: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "$activeStates",
                style: const TextStyle(
                  color: _Palette.purple,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: " / $totalStates",
                style: const TextStyle(
                  color: _Palette.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 700;
          if (wide) {
            return Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          }
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: cards,
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget valueWidget;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      shadow: [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 18,
          spreadRadius: 1,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          DefaultTextStyle(
            style: const TextStyle(
              color: _Palette.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            child: valueWidget,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _Palette.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animates a number counting up from 0 to [value] whenever it changes.
class _AnimatedNumber extends StatelessWidget {
  final double value;
  final int decimals;
  final String suffix;

  const _AnimatedNumber({
    required this.value,
    this.decimals = 0,
    this.suffix = "",
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        final text =
            decimals == 0
                ? val.round().toString()
                : val.toStringAsFixed(decimals);
        return Text("$text$suffix");
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Selected-state quick view + hint
// ---------------------------------------------------------------------------
class _SelectedStateHint extends StatelessWidget {
  const _SelectedStateHint();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
        child: Text(
          "Tap any state on the map to explore civic analytics",
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selected-state quick view bar
//
// FIXED VERSION: avoids the horizontal overflow that previously hid the
// "View Helplines" button on narrow screens. The chip row now wraps, and
// "View Helpline Numbers" is a full-width button on its own row so it is
// always visible and tappable.
// ---------------------------------------------------------------------------
class _SelectedStateBar extends StatelessWidget {
  final StateIssueData data;
  final String displayName;
  final VoidCallback onViewDetails;
  final VoidCallback onClose;

  const _SelectedStateBar({
    super.key,
    required this.data,
    required this.displayName,
    required this.onViewDetails,
    required this.onClose,
  });

  String get _tierLabel {
    if (data.healthScore >= 0.65) return "Low Issues";
    if (data.healthScore >= 0.35) return "Medium Issues";
    return "High Issues";
  }

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: data.stateColor.withOpacity(0.35),
      shadow: [
        BoxShadow(
          color: data.stateColor.withOpacity(0.10),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── top row: color dot + name/tier + percentage + close ──────
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.stateColor,
                  boxShadow: [
                    BoxShadow(
                      color: data.stateColor.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _tierLabel,
                      style: TextStyle(
                        color: data.stateColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${(data.healthScore * 100).round()}%",
                style: TextStyle(
                  color: data.stateColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, color: Colors.white38, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── stat chips row (wraps on narrow screens) ──────────────────
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _StatChip(
                icon: Icons.warning_amber_rounded,
                label: "${data.openIssues} open",
                color: _Palette.danger,
              ),
              _StatChip(
                icon: Icons.check_circle_outline,
                label: "${data.resolvedIssues} resolved",
                color: _Palette.success,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── full-width "View Helplines" button — never gets clipped ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: const Text("View Helpline Numbers"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.accent.withOpacity(0.15),
                foregroundColor: _Palette.accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _Palette.accent.withOpacity(0.35)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

// ---------------------------------------------------------------------------
// Map glass panel
// ---------------------------------------------------------------------------
class _MapGlassPanel extends StatelessWidget {
  final AnimationController pulse;
  final Widget child;

  const _MapGlassPanel({required this.pulse, required this.child});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 28,
      padding: EdgeInsets.zero,
      borderColor: Colors.white.withOpacity(0.06),
      shadow: [
        BoxShadow(
          color: _Palette.accent.withOpacity(0.10),
          blurRadius: 40,
          spreadRadius: 6,
        ),
      ],
      child: Stack(
        children: [
          // subtle animated radial glow behind the map
          Positioned.fill(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.05),
                      radius: 0.95 + (pulse.value * 0.05),
                      colors: [
                        _Palette.accent.withOpacity(0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.75],
                    ),
                  ),
                );
              },
            ),
          ),
          // faint grid lines
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  children: [
                    const Text(
                      "India Civic Health Map",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _Palette.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _Palette.success.withOpacity(0.35),
                        ),
                      ),
                      child: const Text(
                        "LIVE DATA",
                        style: TextStyle(
                          color: _Palette.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tap any state to explore civic analytics",
                    style: TextStyle(
                      color: _Palette.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              Expanded(child: RepaintBoundary(child: child)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Very light static grid — purely decorative, draws once.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.025)
          ..strokeWidth = 1;

    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Floating analytics panel (legend)
// ---------------------------------------------------------------------------
class _AnalyticsPanel extends StatelessWidget {
  final List<StateIssueData> dataSource;

  const _AnalyticsPanel({required this.dataSource});

  @override
  Widget build(BuildContext context) {
    final low = dataSource.where((d) => d.healthScore >= 0.65).toList();
    final medium =
        dataSource
            .where((d) => d.healthScore >= 0.35 && d.healthScore < 0.65)
            .toList();
    final high = dataSource.where((d) => d.healthScore < 0.35).toList();

    double avgResolved(List<StateIssueData> list) {
      if (list.isEmpty) return 0;
      final total = list.fold<double>(0, (s, d) => s + d.healthScore);
      return (total / list.length) * 100;
    }

    final items = [
      _LegendData(
        color: _Palette.success,
        title: "Low Issues",
        count: low.length,
        resolvedPct: avgResolved(low),
      ),
      _LegendData(
        color: _Palette.warning,
        title: "Medium Issues",
        count: medium.length,
        resolvedPct: avgResolved(medium),
      ),
      _LegendData(
        color: _Palette.danger,
        title: "High Issues",
        count: high.length,
        resolvedPct: avgResolved(high),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 600;
          if (wide) {
            return Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _LegendChip(data: items[i])),
                ],
              ],
            );
          }
          return Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _LegendChip(data: items[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LegendData {
  final Color color;
  final String title;
  final int count;
  final double resolvedPct;

  _LegendData({
    required this.color,
    required this.title,
    required this.count,
    required this.resolvedPct,
  });
}

class _LegendChip extends StatelessWidget {
  final _LegendData data;

  const _LegendChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: data.color.withOpacity(0.18),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color,
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.55),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: data.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "${data.count} states · ${data.resolvedPct.toStringAsFixed(0)}% resolved",
                  style: const TextStyle(
                    color: _Palette.textSecondary,
                    fontSize: 11.5,
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

// ---------------------------------------------------------------------------
// State details bottom sheet
// ---------------------------------------------------------------------------
class _StateDetailsSheet extends StatelessWidget {
  final StateIssueData data;
  final String displayName;

  const _StateDetailsSheet({required this.data, required this.displayName});

  String get _tierLabel {
    if (data.healthScore >= 0.65) return "Low Issues";
    if (data.healthScore >= 0.35) return "Medium Issues";
    return "High Issues";
  }

  @override
  Widget build(BuildContext context) {
    final total = data.openIssues + data.resolvedIssues;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: _Palette.bgSurfaceTint.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: data.stateColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: data.stateColor.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    _tierLabel,
                    style: TextStyle(
                      color: data.stateColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                _DetailRow(
                  icon: Icons.warning_amber_rounded,
                  iconColor: _Palette.danger,
                  label: "Open Issues",
                  value: "${data.openIssues}",
                ),
                _DetailRow(
                  icon: Icons.check_circle_outline,
                  iconColor: _Palette.success,
                  label: "Resolved Issues",
                  value: "${data.resolvedIssues}",
                ),
                _DetailRow(
                  icon: Icons.percent_rounded,
                  iconColor: _Palette.warning,
                  label: "Response Rate",
                  value: "${(data.healthScore * 100).toStringAsFixed(1)}%",
                ),
                _DetailRow(
                  icon: Icons.summarize_outlined,
                  iconColor: _Palette.accent,
                  label: "Total Reports",
                  value: "$total",
                ),

                const SizedBox(height: 12),
                Text(
                  "Resolution Progress",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: data.healthScore),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return LinearProgressIndicator(
                        value: val,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          data.stateColor,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _Palette.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
