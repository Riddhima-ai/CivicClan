import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'report_issue_page.dart';
import 'issue_details_page.dart';
import 'IndiaCivicDashboard_realtime.dart';

// ─────────────────────────────────────────────
//  COLOR TOKENS
// ─────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF030712);
  static const surface = Color(0x0DFFFFFF);
  static const border = Color(0x14FFFFFF);
  static const primary = Color(0xFF2563EB);
  static const accent = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const gold = Color(0xFFD4AF37);
  static const text = Colors.white;
  static const muted = Color(0xFF94A3B8);
}

// ─────────────────────────────────────────────
//  HOME PAGE
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String searchText = '';
  final List<String> indianCities = [
    "Delhi",
    "Dehradun",
    "Dhanbad",
    "Durgapur",
    "Mumbai",
    "Mysore",
    "Hyderabad",
    "Hosur",
    "Bangalore",
    "Bhopal",
    "Chennai",
    "Coimbatore",
    "Kolkata",
    "Kanpur",
    "Lucknow",
    "Ludhiana",
    "Pune",
    "Patna",
    "Jaipur",
    "Jodhpur",
    "Ahmedabad",
    "Amritsar",
    "Surat",
    "Srinagar",
    "Nagpur",
    "Nashik",
    "Indore",
    "Visakhapatnam",
    "Vijayawada",
  ];
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    if (email.isEmpty) return 'Citizen';
    final name = email.split('@').first;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(child: _MeshBackground(controller: _bgCtrl)),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSearchBar(),
                  const SizedBox(height: 32),
                  _buildStatsRow(),
                  const SizedBox(height: 28),
                  _buildCivicPulseBanner(),
                  const SizedBox(height: 36),
                  _buildTrendingHeader(),
                  const SizedBox(height: 20),
                  _buildIssueStream(),
                ],
              ),
            ),
          ),
          _buildFloatingPill(),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  color: _C.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _displayName,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_C.primary, _C.accent]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Building better cities together',
                    style: TextStyle(
                      color: _C.muted,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _ProfileChip(),
      ],
    );
  }

  // ── SEARCH ────────────────────────────────
  Widget _buildSearchBar() {
    return _GlassContainer(
      radius: 28,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 60,
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }

            return indianCities.where(
              (city) => city.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },

          onSelected: (String selection) {
            setState(() {
              searchText = selection.toLowerCase();
            });
          },

          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white),

              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },

              decoration: InputDecoration(
                border: InputBorder.none,

                hintText: "Search location (Hyderabad, Delhi...)",

                hintStyle: const TextStyle(color: Colors.white54),

                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Colors.white70,
                ),

                suffixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: _C.muted,
                    size: 18,
                  ),
                ),
              ),
            );
          },

          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 350,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff111827),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);

                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                        ),
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── STATS ─────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(
          value: '245',
          label: 'Open Issues',
          trend: '↑ 12 today',
          trendColor: const Color(0xFFEF4444),
          icon: Icons.list_alt_rounded,
          iconColor: const Color(0xFFEF4444),
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '120',
          label: 'Resolved',
          trend: '92% rate',
          trendColor: _C.success,
          icon: Icons.check_circle_outline_rounded,
          iconColor: _C.success,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '1.2K',
          label: 'Community',
          trend: 'Growing',
          trendColor: _C.accent,
          icon: Icons.people_outline_rounded,
          iconColor: _C.accent,
        ),
      ],
    );
  }

  // ── CIVIC PULSE BANNER ────────────────────
  Widget _buildCivicPulseBanner() {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IndiaCivicDashboard_realtime(),
            ),
          ),
      child: _GlassContainer(
        radius: 24,
        borderColor: _C.gold.withOpacity(0.25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.primary.withOpacity(0.18), _C.accent.withOpacity(0.06)],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _C.accent.withOpacity(0.6),
                    _C.primary.withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: _C.gold.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.public, color: Colors.white, size: 42),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _C.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: _C.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'National Civic Pulse',
                    style: TextStyle(
                      color: _C.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Real-time India Civic Intelligence',
                    style: TextStyle(color: _C.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _PulseStat(
                        icon: Icons.people_outline,
                        label: '1,293',
                        sub: 'Reports',
                      ),
                      const SizedBox(width: 18),
                      _PulseStat(
                        icon: Icons.map_outlined,
                        label: '24',
                        sub: 'States',
                      ),
                      const SizedBox(width: 18),
                      _PulseStat(
                        icon: Icons.verified_outlined,
                        label: '92%',
                        sub: 'Response',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.accent.withOpacity(0.15),
                border: Border.all(color: _C.accent.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: _C.accent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TRENDING HEADER ───────────────────────
  Widget _buildTrendingHeader() {
    return Row(
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_C.primary, _C.accent],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Trending Issues',
          style: TextStyle(
            color: _C.text,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Row(
          children: const [
            Text('View all', style: TextStyle(color: _C.accent, fontSize: 13)),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, color: _C.accent, size: 12),
          ],
        ),
      ],
    );
  }

  // ── ISSUE STREAM ──────────────────────────
  Widget _buildIssueStream() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('issues')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: _C.accent,
                strokeWidth: 1.5,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyState();
        }
        final docs = snapshot.data!.docs;
        return Column(
          children:
              docs.map((doc) {
                final issue = {
                  'id': doc.id,
                  ...(doc.data() as Map<String, dynamic>),
                };
                final location =
                    (issue['location'] ?? '').toString().toLowerCase();
                if (searchText.isNotEmpty && !location.contains(searchText)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _IssueCard(issue: issue),
                );
              }).toList(),
        );
      },
    );
  }

  // ── FLOATING PILL ─────────────────────────
  Widget _buildFloatingPill() {
    return Positioned(
      bottom: 28,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportIssuePage()),
              ),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.accent.withOpacity(0.45),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Report New Issue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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

// ─────────────────────────────────────────────
//  PROFILE CHIP
// ─────────────────────────────────────────────
class _ProfileChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'logout') {
          await FirebaseAuth.instance.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      },
      itemBuilder:
          (context) => const [
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
      child: _GlassContainer(
        radius: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: _C.primary,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _C.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.bg, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _C.muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value, label, trend;
  final Color trendColor, iconColor;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.trend,
    required this.trendColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: _C.text,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _C.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              trend,
              style: TextStyle(
                color: trendColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PULSE STAT
// ─────────────────────────────────────────────
class _PulseStat extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _PulseStat({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _C.accent, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _C.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(sub, style: const TextStyle(color: _C.muted, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  ISSUE CARD
// ─────────────────────────────────────────────
class _IssueCard extends StatelessWidget {
  final Map<String, dynamic> issue;
  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasImage =
        issue['image'] != null && issue['image'].toString().isNotEmpty;
    final status = issue['status'] ?? 'Pending';
    final Color statusColor =
        status == 'Resolved'
            ? _C.success
            : status == 'Verified'
            ? _C.accent
            : const Color(0xFFF59E0B);

    return _GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image block
          if (hasImage)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: Image.memory(
                    base64Decode(issue['image']),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, _C.bg.withOpacity(0.7)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _C.bg.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.border),
                    ),
                    child: Text(
                      issue['category'] ?? 'General',
                      style: const TextStyle(
                        color: _C.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasImage)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _C.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _C.accent.withOpacity(0.3)),
                        ),
                        child: Text(
                          issue['category'] ?? 'General',
                          style: const TextStyle(
                            color: _C.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (currentUser != null &&
                        issue['userId'] == currentUser.uid)
                      _DeleteButton(issueId: issue['id']),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  issue['title'] ?? 'No Title',
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _C.muted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        issue['location'] ?? 'Unknown Location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _C.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  issue['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      color: _C.muted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'community',
                      style: TextStyle(color: _C.muted, fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IssueDetailsPage(issue: issue),
                            ),
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _C.accent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DELETE BUTTON
// ─────────────────────────────────────────────
class _DeleteButton extends StatelessWidget {
  final String issueId;
  const _DeleteButton({required this.issueId});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: Color(0xFFEF4444),
        size: 20,
      ),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Delete Issue',
                  style: TextStyle(color: _C.text),
                ),
                content: const Text(
                  'Are you sure you want to delete this issue?',
                  style: TextStyle(color: _C.muted),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: _C.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
        );
        if (confirm == true) {
          await FirebaseFirestore.instance
              .collection('issues')
              .doc(issueId)
              .delete();
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: const [
          Icon(Icons.inbox_outlined, color: _C.muted, size: 48),
          SizedBox(height: 16),
          Text(
            'No Issues Reported Yet',
            style: TextStyle(
              color: _C.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to report a civic issue\nin your neighbourhood.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.muted, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GLASS CONTAINER
// ─────────────────────────────────────────────
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Gradient? gradient;

  const _GlassContainer({
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.03),
              ],
            ),
        border: Border.all(color: borderColor ?? _C.border, width: 1),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  ANIMATED MESH BACKGROUND
// ─────────────────────────────────────────────
class _MeshBackground extends StatelessWidget {
  final AnimationController controller;
  const _MeshBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(painter: _MeshPainter(controller.value)),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF030712),
    );

    void blob(double cx, double cy, double r, Color c) {
      final paint =
          Paint()
            ..shader = RadialGradient(
              colors: [c, Colors.transparent],
            ).createShader(
              Rect.fromCircle(
                center: Offset(cx * size.width, cy * size.height),
                radius: r,
              ),
            );
      canvas.drawCircle(Offset(cx * size.width, cy * size.height), r, paint);
    }

    final s1 = math.sin(t * math.pi * 2);
    final s2 = math.sin(t * math.pi * 2 + 1.2);

    blob(
      0.15 + s1 * 0.04,
      0.12 + s2 * 0.03,
      size.width * 0.45,
      const Color(0xFF1E3A8A).withOpacity(0.28),
    );
    blob(
      0.85 + s2 * 0.04,
      0.35 + s1 * 0.05,
      size.width * 0.40,
      const Color(0xFF1D4ED8).withOpacity(0.18),
    );
    blob(
      0.45 + s1 * 0.03,
      0.75 + s2 * 0.04,
      size.width * 0.38,
      const Color(0xFF0369A1).withOpacity(0.14),
    );

    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.025)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yBase = size.height * (0.1 + i * 0.15);
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 8) {
        final y =
            yBase +
            math.sin(
                  (x / size.width * math.pi * 3) + t * math.pi * 2 + i * 0.5,
                ) *
                14;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t;
}
