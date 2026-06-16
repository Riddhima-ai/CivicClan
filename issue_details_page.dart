import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class IssueDetailsPage extends StatefulWidget {
  final Map<String, dynamic> issue;

  const IssueDetailsPage({super.key, required this.issue});

  @override
  State<IssueDetailsPage> createState() => _IssueDetailsPageState();
}

class _IssueDetailsPageState extends State<IssueDetailsPage> {
  int approvals = 0;
  int disapprovals = 0;
  late String status;
  String? userVote;
  bool _isResolving = false;

  final TextEditingController commentController = TextEditingController();

  // Theme colors (matching the design)
  static const Color bgColor = Color(0xff05060F);
  static const Color cardColor = Color(0xff0E1326);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF2563EB);

  // ── Lively gradient/space background ──
  Widget _buildBackground() {
    return Stack(
      children: [
        // Base gradient
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

        // Big glowing purple blob - top right
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

        // Glowing blue blob - middle left
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

        // Glowing teal/cyan blob - bottom right
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

        // Small "planet" - mid right
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

        // Small "planet" - lower left
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

        // Scattered stars
        ..._buildStars(),
      ],
    );
  }

  // ── Helper: scattered star dots ──
  List<Widget> _buildStars() {
    final positions = <Offset>[
      const Offset(40, 60),
      const Offset(120, 180),
      const Offset(300, 40),
      const Offset(80, 320),
      const Offset(250, 500),
      const Offset(340, 650),
      const Offset(20, 750),
      const Offset(200, 900),
      const Offset(330, 1000),
      const Offset(60, 1100),
      const Offset(280, 1250),
      const Offset(150, 1400),
      const Offset(310, 1500),
      const Offset(50, 1600),
    ];

    return positions.map((pos) {
      return Positioned(
        top: pos.dy,
        left: pos.dx,
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    approvals = widget.issue['approvals'] ?? 0;
    disapprovals = widget.issue['disapprovals'] ?? 0;
    super.initState();
    _loadUserVote();
    final raw = widget.issue['status'] ?? 'open';
    status = raw.toString().toLowerCase();
  }

  Future<void> _loadUserVote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final voteDoc =
        await FirebaseFirestore.instance
            .collection('issues')
            .doc(widget.issue['id'])
            .collection('votes')
            .doc(uid)
            .get();

    if (voteDoc.exists && mounted) {
      setState(() {
        userVote = voteDoc['vote'];
      });
    }
  }

  Future<void> _approveIssue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final issueRef = FirebaseFirestore.instance
        .collection('issues')
        .doc(widget.issue['id']);

    final voteRef = issueRef.collection('votes').doc(uid);

    final voteDoc = await voteRef.get();

    if (!voteDoc.exists) {
      await voteRef.set({'vote': 'approve'});
      await issueRef.update({'approvals': FieldValue.increment(1)});

      if (mounted) {
        setState(() {
          approvals++;
          userVote = 'approve';
        });
      }
    }
  }

  Future<void> _rejectIssue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final issueRef = FirebaseFirestore.instance
        .collection('issues')
        .doc(widget.issue['id']);

    final voteRef = issueRef.collection('votes').doc(uid);

    final voteDoc = await voteRef.get();

    if (!voteDoc.exists) {
      await voteRef.set({'vote': 'reject'});
      await issueRef.update({'disapprovals': FieldValue.increment(1)});

      if (mounted) {
        setState(() {
          disapprovals++;
          userVote = 'reject';
        });
      }
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  bool get isResolved => status == 'resolved';

  String _extractState(String location) {
    final parts = location.split(',');
    return parts.last.trim();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
    }
    return ts.toString();
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final location = issue['location'] ?? '';
    final stateName = issue['state'] ?? _extractState(location);
    final title = issue['title'] ?? 'No Title';
    final category = issue['category'] ?? '';
    final description = issue['description'] ?? '';
    final tag = issue['tag'] ?? '';
    final date = issue['date'] ?? _formatTimestamp(issue['createdAt']);
    final time = issue['time'] ?? '';
    final isVerified = issue['verified'] == true;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              "Issue Details",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (issue['id'] != null)
              Text(
                "Issue #${issue['id']}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 70,
                16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Verified badge ──
                  if (isVerified)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.green.withOpacity(.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "VERIFIED",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Header card: icon, title, category, location/date/time ──
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: purple.withOpacity(.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.warning_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (category.toString().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            color: purple,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              color: purple,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            children: [
                              if (location.toString().isNotEmpty)
                                _infoChip(
                                  Icons.location_on,
                                  location.toString(),
                                  Colors.redAccent,
                                ),
                              if (date.toString().isNotEmpty)
                                _infoChip(
                                  Icons.calendar_today,
                                  date.toString(),
                                  Colors.white60,
                                ),
                              if (time.toString().isNotEmpty)
                                _infoChip(
                                  Icons.access_time,
                                  time.toString(),
                                  Colors.white60,
                                ),
                            ],
                          ),
                          if (stateName.toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _infoChip(
                              Icons.map_outlined,
                              "State: $stateName",
                              purple,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Image ──
                  _card(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child:
                          (issue['image'] != null &&
                                  issue['image'].toString().isNotEmpty)
                              ? Image.memory(
                                base64Decode(issue['image']),
                                height: 240,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                height: 240,
                                width: double.infinity,
                                color: Colors.grey.shade800,
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.white54,
                                    size: 60,
                                  ),
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Status badge (Open / Resolved) ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isResolved
                                ? Colors.green.withOpacity(.2)
                                : Colors.orange.withOpacity(.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isResolved ? "Resolved" : "Open",
                        style: TextStyle(
                          color: isResolved ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Description + Timeline row ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final descriptionCard = _card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(
                                Icons.description,
                                "Issue Description",
                              ),
                              const SizedBox(height: 14),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              if (tag.toString().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: purple.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "# $tag",
                                    style: const TextStyle(
                                      color: purple,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );

                      final timelineCard = _buildTimeline();

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: descriptionCard),
                            const SizedBox(width: 16),
                            Expanded(child: timelineCard),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          descriptionCard,
                          const SizedBox(height: 16),
                          timelineCard,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Approve / Reject ──
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.thumb_up),
                          label: Text("Approve ($approvals)"),
                          onPressed: userVote == null ? _approveIssue : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.thumb_down),
                          label: Text("Reject ($disapprovals)"),
                          onPressed: userVote == null ? _rejectIssue : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Stats row: Supporters / Comments / Share ──
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          _statItem(
                            icon: Icons.thumb_up,
                            iconBg: purple.withOpacity(.25),
                            iconColor: purple,
                            value: "${approvals + disapprovals}",
                            label: "Supporters",
                            sub: "Thank you!",
                            subColor: purple,
                          ),
                          _statItem(
                            icon: Icons.chat_bubble,
                            iconBg: blue.withOpacity(.25),
                            iconColor: blue,
                            value: "—",
                            label: "Comments",
                            sub: "Join the discussion",
                            subColor: blue,
                            streamCount:
                                FirebaseFirestore.instance
                                    .collection('issues')
                                    .doc(widget.issue['id'])
                                    .collection('comments')
                                    .snapshots(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Community Comments ──
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(Icons.forum, "Community Comments"),
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('issues')
                                    .doc(widget.issue['id'])
                                    .collection('comments')
                                    .orderBy('createdAt')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: purple,
                                    ),
                                  ),
                                );
                              }
                              final docs = snapshot.data!.docs;
                              if (docs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    "No comments yet. Be the first to comment!",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                );
                              }
                              return Column(
                                children:
                                    docs.map((doc) {
                                      final comment =
                                          doc.data() as Map<String, dynamic>;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(.05),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: purple,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(
                                            comment['text'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle: Text(
                                            comment['user'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Add a comment...",
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Post Comment"),
                              onPressed: () async {
                                if (commentController.text.trim().isEmpty)
                                  return;
                                await FirebaseFirestore.instance
                                    .collection('issues')
                                    .doc(widget.issue['id'])
                                    .collection('comments')
                                    .add({
                                      'text': commentController.text.trim(),
                                      'user':
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.email,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                commentController.clear();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Mark as Resolved button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isResolved ? Colors.grey.shade700 : blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        isResolved
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        isResolved
                            ? "Already Resolved"
                            : (_isResolving
                                ? "Updating..."
                                : "Mark as Resolved"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed:
                          isResolved || _isResolving
                              ? null
                              : () async {
                                setState(() => _isResolving = true);

                                await FirebaseFirestore.instance
                                    .collection('issues')
                                    .doc(widget.issue['id'])
                                    .update({
                                      'status': 'resolved',
                                      'state': stateName,
                                      'resolvedAt':
                                          FieldValue.serverTimestamp(),
                                      'resolvedBy':
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.email,
                                    });

                                if (mounted) {
                                  setState(() {
                                    status = 'resolved';
                                    _isResolving = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "✅ Issue resolved! $stateName map will update automatically.",
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                }
                              },
                    ),
                  ),

                  // ── Reopen button (shows only when resolved) ──
                  if (isResolved) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.replay, color: Colors.orange),
                        label: const Text(
                          "Reopen Issue",
                          style: TextStyle(color: Colors.orange, fontSize: 16),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('issues')
                              .doc(widget.issue['id'])
                              .update({
                                'status': 'open',
                                'state': stateName,
                                'resolvedAt': null,
                              });
                          if (mounted) setState(() => status = 'open');
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Support this Issue button ──
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.favorite, color: Colors.white),
                        label: const Text(
                          "Support this Issue",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: userVote == null ? _approveIssue : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: card container ──
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  // ── Helper: section header with icon ──
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: purple.withOpacity(.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: purple, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Helper: small info chip (location/date/time/state) ──
  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  // ── Helper: stat item for Supporters / Comments / Share row ──
  Widget _statItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String sub,
    required Color subColor,
    Stream<QuerySnapshot>? streamCount,
    VoidCallback? onTap,
  }) {
    Widget valueWidget;
    if (streamCount != null) {
      valueWidget = StreamBuilder<QuerySnapshot>(
        stream: streamCount,
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return Text(
            "$count",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      );
    } else {
      valueWidget = Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              if (value.isNotEmpty) valueWidget,
              if (value.isNotEmpty) const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  color: subColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: timeline card ──
  Widget _buildTimeline() {
    final issue = widget.issue;

    final reportedAt = _formatTimestamp(issue['createdAt']);
    final verifiedAt =
        issue['verifiedAt'] != null
            ? _formatTimestamp(issue['verifiedAt'])
            : null;
    final assignedAt =
        issue['assignedAt'] != null
            ? _formatTimestamp(issue['assignedAt'])
            : null;
    final inProgress = status == 'in progress' || status == 'resolved';
    final resolvedAt =
        isResolved ? _formatTimestamp(issue['resolvedAt']) : null;

    return _card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.access_time, "Issue Timeline"),
            const SizedBox(height: 16),
            _timelineStep(
              label: "Reported",
              sub: reportedAt.isNotEmpty ? reportedAt : "—",
              done: true,
              isLast: false,
            ),
            _timelineStep(
              label: "Verified",
              sub:
                  verifiedAt ??
                  (issue['verified'] == true ? "Done" : "Pending"),
              done: issue['verified'] == true,
              isLast: false,
            ),
            _timelineStep(
              label: "Assigned",
              sub:
                  assignedAt ??
                  (issue['assigned'] == true ? "Done" : "Pending"),
              done: issue['assigned'] == true,
              current: issue['assigned'] == true && !inProgress,
              isLast: false,
            ),
            _timelineStep(
              label: "In Progress",
              sub: inProgress ? "In progress" : "Pending",
              done: inProgress,
              isLast: false,
            ),
            _timelineStep(
              label: "Resolved",
              sub: resolvedAt ?? (isResolved ? "Done" : "Pending"),
              done: isResolved,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: single timeline step ──
  Widget _timelineStep({
    required String label,
    required String sub,
    required bool done,
    bool current = false,
    required bool isLast,
  }) {
    final Color circleColor =
        done ? Colors.green : (current ? blue : Colors.white24);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done
                          ? Colors.green.withOpacity(.2)
                          : (current
                              ? blue.withOpacity(.2)
                              : Colors.transparent),
                  border: Border.all(color: circleColor, width: 2),
                ),
                child:
                    done
                        ? const Icon(Icons.check, color: Colors.green, size: 14)
                        : (current
                            ? Container(
                              margin: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: blue,
                                shape: BoxShape.circle,
                              ),
                            )
                            : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? Colors.green : Colors.white12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
