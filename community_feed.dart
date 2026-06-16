import 'package:flutter/material.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  String selectedCategory = "All";

  // Theme colors
  static const Color bgColor = Color(0xff05060F);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF2563EB);

  List<Map<String, dynamic>> issues = [
    {
      "title": "Pothole Near Main Road",
      "category": "Pothole",
      "status": "Pending",
      "approvals": 12,
      "disapprovals": 2,
    },
    {
      "title": "Street Light Not Working",
      "category": "Street Light",
      "status": "Pending",
      "approvals": 8,
      "disapprovals": 1,
    },
    {
      "title": "Garbage Overflow",
      "category": "Garbage",
      "status": "Verified",
      "approvals": 20,
      "disapprovals": 0,
    },
  ];

  final Map<String, IconData> categoryIcons = const {
    "All": Icons.apps_rounded,
    "Pothole": Icons.warning_amber_rounded,
    "Street Light": Icons.lightbulb_outline,
    "Garbage": Icons.delete_outline,
  };

  IconData _iconForCategory(String category) {
    switch (category) {
      case "Pothole":
        return Icons.warning_amber_rounded;
      case "Street Light":
        return Icons.lightbulb_outline;
      case "Garbage":
        return Icons.delete_outline;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Resolved":
        return Colors.green;
      case "Verified":
        return Colors.cyanAccent;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredIssues =
        selectedCategory == "All"
            ? issues
            : issues
                .where((issue) => issue["category"] == selectedCategory)
                .toList();

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Community Feed",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top > 0 ? 8 : 70,
                ),

                // ── Header tagline ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [purple, blue],
                            ).createShader(bounds),
                        child: const Text(
                          "Civic Pulse",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "What's happening in your community right now",
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Quick stats row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _statBadge(
                        icon: Icons.list_alt_rounded,
                        label: "Total",
                        value: "${issues.length}",
                        color: purple,
                      ),
                      const SizedBox(width: 10),
                      _statBadge(
                        icon: Icons.verified_outlined,
                        label: "Verified",
                        value:
                            "${issues.where((i) => i['status'] == 'Verified').length}",
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 10),
                      _statBadge(
                        icon: Icons.check_circle_outline,
                        label: "Resolved",
                        value:
                            "${issues.where((i) => i['status'] == 'Resolved').length}",
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Filter chips ──
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      buildFilterChip("All"),
                      buildFilterChip("Pothole"),
                      buildFilterChip("Street Light"),
                      buildFilterChip("Garbage"),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Issue list ──
                Expanded(
                  child:
                      filteredIssues.isEmpty
                          ? Center(
                            child: Text(
                              "No issues in this category yet",
                              style: TextStyle(
                                color: Colors.white.withOpacity(.5),
                              ),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filteredIssues.length,
                            itemBuilder: (context, index) {
                              final issue = filteredIssues[index];
                              return _buildIssueCard(issue);
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

  // ── Issue card ──
  Widget _buildIssueCard(Map<String, dynamic> issue) {
    final statusColor = _statusColor(issue["status"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(.06),
            Colors.white.withOpacity(.02),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [purple.withOpacity(.35), blue.withOpacity(.25)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    _iconForCategory(issue["category"]),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue["title"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.label_outline, color: purple, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            issue["category"],
                            style: const TextStyle(
                              color: purple,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(.4)),
                  ),
                  child: Text(
                    issue["status"],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(.08), height: 1),
            const SizedBox(height: 14),

            // ── Approve / Reject ──
            Row(
              children: [
                Expanded(
                  child: _voteButton(
                    icon: Icons.thumb_up_alt_outlined,
                    count: issue["approvals"],
                    color: Colors.green,
                    onTap: () {
                      setState(() {
                        issue["approvals"]++;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _voteButton(
                    icon: Icons.thumb_down_alt_outlined,
                    count: issue["disapprovals"],
                    color: Colors.redAccent,
                    onTap: () {
                      setState(() {
                        issue["disapprovals"]++;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Mark Resolved ──
            SizedBox(
              width: double.infinity,
              child:
                  issue["status"] == "Resolved"
                      ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Resolved",
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              issue["status"] = "Resolved";
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  "Issue marked as resolved!",
                                ),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          },
                          child: const Text(
                            "Mark Resolved",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vote button (approve/reject) ──
  Widget _voteButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              "$count",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top stat badge ──
  Widget _statBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(.05),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(.6),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chip ──
  Widget buildFilterChip(String category) {
    final bool selected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient:
                selected
                    ? const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                    )
                    : null,
            color: selected ? null : Colors.white.withOpacity(.05),
            border: Border.all(
              color:
                  selected ? Colors.transparent : Colors.white.withOpacity(.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                categoryIcons[category] ?? Icons.label_outline,
                size: 16,
                color: selected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Lively cosmic background ──
  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff05060F),
                Color(0xff0A0E2A),
                Color(0xff140B2E),
                Color(0xff05060F),
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [purple.withOpacity(.35), purple.withOpacity(0)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 350,
          left: -150,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [blue.withOpacity(.30), blue.withOpacity(0)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.cyan.withOpacity(.25),
                  Colors.cyan.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 700,
          right: 30,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [purple.withOpacity(.45), blue.withOpacity(.15)],
              ),
              boxShadow: [
                BoxShadow(
                  color: purple.withOpacity(.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: 10,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [blue.withOpacity(.5), Colors.cyan.withOpacity(.2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: blue.withOpacity(.35),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
