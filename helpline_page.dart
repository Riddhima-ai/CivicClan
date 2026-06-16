import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Palette — matches the "Luxury Dark Analytics" theme used on the map page
// ---------------------------------------------------------------------------
class _Palette {
  static const bgDeep = Color(0xFF020617);
  static const bgMid = Color(0xFF07111D);
  static const bgSurfaceTint = Color(0xFF0B1220);

  static const glassFill = Color(0x0DFFFFFF); // 5% white
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
// Category metadata — icon + accent color per civic issue type
// ---------------------------------------------------------------------------
class HelplineCategory {
  final String name;
  final IconData icon;
  final Color color;

  const HelplineCategory(this.name, this.icon, this.color);
}

const List<HelplineCategory> kHelplineCategories = [
  HelplineCategory("Potholes", Icons.construction_rounded, _Palette.warning),
  HelplineCategory(
    "Garbage Collection",
    Icons.delete_outline_rounded,
    _Palette.success,
  ),
  HelplineCategory("Water Leakage", Icons.water_drop_outlined, _Palette.accent),
  HelplineCategory(
    "Street Lights",
    Icons.lightbulb_outline_rounded,
    _Palette.gold,
  ),
  HelplineCategory("Traffic Signals", Icons.traffic_rounded, _Palette.danger),
  HelplineCategory(
    "Public Transport",
    Icons.directions_bus_filled_outlined,
    _Palette.purple,
  ),
  HelplineCategory(
    "Sewage & Drainage",
    Icons.plumbing_outlined,
    Color(0xFF06B6D4),
  ),
  HelplineCategory("Stray Animals", Icons.pets_rounded, Color(0xFFF472B6)),
];

// ---------------------------------------------------------------------------
// Helpline data
// ---------------------------------------------------------------------------
//
// NOTE: The numbers below follow common municipal / state-level helpline
// patterns used across India (e.g. 1916 for water boards, 1912 for
// electricity / streetlight complaints under state DISCOMs, 1969 for
// PWD road grievances, 1962 for animal husbandry helplines). Several
// states share the same generic numbers in `_defaultHelplines` below.
//
// ⚠️ Please verify and update these with the official numbers for your
// target states/cities before shipping to production.
//
const Map<String, String> _defaultHelplines = {
  "Potholes": "1969",
  "Garbage Collection": "1969",
  "Water Leakage": "1916",
  "Street Lights": "1912",
  "Traffic Signals": "103",
  "Public Transport": "1800-180-1551",
  "Sewage & Drainage": "1916",
  "Stray Animals": "1962",
};

// State-specific overrides. Anything not listed here falls back to
// `_defaultHelplines`. Keys must match the `_displayNames` strings used
// on the map page exactly.
const Map<String, Map<String, String>> _stateOverrides = {
  "Karnataka": {
    "Potholes": "080-22221188",
    "Garbage Collection": "080-22660000",
    "Water Leakage": "1916",
    "Street Lights": "1912",
    "Traffic Signals": "080-22943322",
    "Public Transport": "080-44554455",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
  "Telangana": {
    "Potholes": "040-21111111",
    "Garbage Collection": "040-21111111",
    "Water Leakage": "155313",
    "Street Lights": "1912",
    "Traffic Signals": "040-27852333",
    "Public Transport": "040-69440000",
    "Sewage & Drainage": "155313",
    "Stray Animals": "1962",
  },
  "Maharashtra": {
    "Potholes": "1916",
    "Garbage Collection": "1916",
    "Water Leakage": "1916",
    "Street Lights": "1912",
    "Traffic Signals": "103",
    "Public Transport": "1800-220-110",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
  "Delhi": {
    "Potholes": "1031",
    "Garbage Collection": "155305",
    "Water Leakage": "1916",
    "Street Lights": "1533",
    "Traffic Signals": "1095",
    "Public Transport": "1800-180-2877",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
  "Tamil Nadu": {
    "Potholes": "1913",
    "Garbage Collection": "1913",
    "Water Leakage": "044-45674567",
    "Street Lights": "1912",
    "Traffic Signals": "103",
    "Public Transport": "1800-419-1100",
    "Sewage & Drainage": "044-45674567",
    "Stray Animals": "1962",
  },
  "Andhra Pradesh": {
    "Potholes": "1100",
    "Garbage Collection": "1100",
    "Water Leakage": "1100",
    "Street Lights": "1912",
    "Traffic Signals": "103",
    "Public Transport": "1800-200-1888",
    "Sewage & Drainage": "1100",
    "Stray Animals": "1962",
  },
  "Gujarat": {
    "Potholes": "1916",
    "Garbage Collection": "1916",
    "Water Leakage": "1916",
    "Street Lights": "1912",
    "Traffic Signals": "103",
    "Public Transport": "1800-233-5500",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
  "West Bengal": {
    "Potholes": "1800-345-3375",
    "Garbage Collection": "1800-345-3375",
    "Water Leakage": "1800-345-3375",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-345-3375",
    "Sewage & Drainage": "1800-345-3375",
    "Stray Animals": "1962",
  },
  "Uttar Pradesh": {
    "Potholes": "1533",
    "Garbage Collection": "1533",
    "Water Leakage": "1533",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-180-2877",
    "Sewage & Drainage": "1533",
    "Stray Animals": "1962",
  },
  "Rajasthan": {
    "Potholes": "1800-180-6127",
    "Garbage Collection": "1800-180-6127",
    "Water Leakage": "1916",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-180-6127",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
  "Punjab": {
    "Potholes": "1100",
    "Garbage Collection": "1100",
    "Water Leakage": "1100",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-180-1234",
    "Sewage & Drainage": "1100",
    "Stray Animals": "1962",
  },
  "Kerala": {
    "Potholes": "1077",
    "Garbage Collection": "1077",
    "Water Leakage": "1916",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-599-1500",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
  "Madhya Pradesh": {
    "Potholes": "1800-233-1234",
    "Garbage Collection": "1800-233-1234",
    "Water Leakage": "1916",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-233-1234",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
  "Haryana": {
    "Potholes": "1100",
    "Garbage Collection": "1100",
    "Water Leakage": "1100",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-180-2345",
    "Sewage & Drainage": "1100",
    "Stray Animals": "1962",
  },
  "Bihar": {
    "Potholes": "1800-345-6188",
    "Garbage Collection": "1800-345-6188",
    "Water Leakage": "1916",
    "Street Lights": "1912",
    "Traffic Signals": "1073",
    "Public Transport": "1800-345-6188",
    "Sewage & Drainage": "1916",
    "Stray Animals": "1962",
  },
};

/// Builds the full helpline map for [stateName], merging defaults with any
/// state-specific overrides. Any state not explicitly listed above still
/// gets a complete set of generic numbers via `_defaultHelplines`.
Map<String, String> getHelplinesForState(String stateName) {
  final merged = Map<String, String>.from(_defaultHelplines);
  final overrides = _stateOverrides[stateName];
  if (overrides != null) merged.addAll(overrides);
  return merged;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class HelplinePage extends StatelessWidget {
  final String stateName;

  const HelplinePage({super.key, required this.stateName});

  @override
  Widget build(BuildContext context) {
    final helplines = getHelplinesForState(stateName);
    final hasOverride = _stateOverrides.containsKey(stateName);

    return Scaffold(
      backgroundColor: _Palette.bgMid,
      body: Stack(
        children: [
          const Positioned.fill(child: _BackgroundLayer()),
          SafeArea(
            child: Column(
              children: [
                _FloatingHeader(stateName: stateName),
                const SizedBox(height: 6),
                if (!hasOverride) const _GenericDataBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: kHelplineCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _EmergencyBanner();
                      }
                      final category = kHelplineCategories[index - 1];
                      final number = helplines[category.name] ?? "—";
                      return _AnimatedEntry(
                        index: index,
                        child: _HelplineCard(
                          category: category,
                          number: number,
                        ),
                      );
                    },
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
// Background — simple radial gradient consistent with the map page
// ---------------------------------------------------------------------------
class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.3,
          colors: [_Palette.bgSurfaceTint, _Palette.bgMid, _Palette.bgDeep],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared glass container
// ---------------------------------------------------------------------------
class _Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final List<BoxShadow>? shadow;

  const _Glass({
    required this.child,
    this.radius = 18,
    this.padding,
    this.borderColor,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(borderRadius: br, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _Palette.glassFill,
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
// Floating header with back button + state name
// ---------------------------------------------------------------------------
class _FloatingHeader extends StatelessWidget {
  final String stateName;

  const _FloatingHeader({required this.stateName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: _Glass(
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stateName,
                    style: const TextStyle(
                      color: _Palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Civic Helpline Directory",
                    style: TextStyle(
                      color: _Palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _Palette.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: _Palette.purple,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner: numbers shown are generic placeholders for this state
// ---------------------------------------------------------------------------
class _GenericDataBanner extends StatelessWidget {
  const _GenericDataBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: _Glass(
        radius: 14,
        borderColor: _Palette.warning.withOpacity(0.25),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: _Palette.warning,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Showing general state helpline numbers. "
                "City-specific numbers may differ.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// National emergency banner
// ---------------------------------------------------------------------------
class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Glass(
        radius: 18,
        borderColor: _Palette.danger.withOpacity(0.3),
        shadow: [
          BoxShadow(
            color: _Palette.danger.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _Palette.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emergency_share_rounded,
                color: _Palette.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "National Emergency",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "All-India emergency response number",
                    style: TextStyle(
                      color: _Palette.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            _CallButton(number: "112", color: _Palette.danger),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staggered fade/slide entrance animation
// ---------------------------------------------------------------------------
class _AnimatedEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Category helpline card
// ---------------------------------------------------------------------------
class _HelplineCard extends StatelessWidget {
  final HelplineCategory category;
  final String number;

  const _HelplineCard({required this.category, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onLongPress: () => _copyNumber(context, number),
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: _Palette.textSecondary,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _CallButton(number: number, color: category.color),
          ],
        ),
      ),
    );
  }

  void _copyNumber(BuildContext context, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied $number to clipboard"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _Palette.bgSurfaceTint,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tap-to-call button
// ---------------------------------------------------------------------------
class _CallButton extends StatelessWidget {
  final String number;
  final Color color;

  const _CallButton({required this.number, required this.color});

  Future<void> _call(BuildContext context) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't launch dialer for $number"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _Palette.bgSurfaceTint,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _call(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Icon(Icons.call_rounded, color: color, size: 18),
      ),
    );
  }
}
