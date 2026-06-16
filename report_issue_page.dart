import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // ORIGINAL STATE / CONTROLLERS — UNCHANGED
  // ===========================================================================
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  String category = "Pothole";
  XFile? image;

  final ImagePicker picker = ImagePicker();

  // ===========================================================================
  // NEW (UI-ONLY) STATE — purely cosmetic, does not touch existing logic
  // ===========================================================================
  bool isSubmitting = false;
  late final AnimationController _pageController;

  // Category -> icon map (purely visual, every original category preserved)
  static const Map<String, IconData> _categoryIcons = {
    "Pothole": Icons.warning_amber_rounded,
    "Garbage": Icons.delete_outline_rounded,
    "Street Light": Icons.lightbulb_outline_rounded,
    "Water Leakage": Icons.water_drop_outlined,
    "Road Damage": Icons.add_road_rounded,
    "Drainage": Icons.water_rounded,
    "Traffic Signal": Icons.traffic_rounded,
    "Illegal Parking": Icons.local_parking_outlined,
    "Public Safety": Icons.shield_outlined,
    "Noise Pollution": Icons.volume_up_outlined,
    "Air Pollution": Icons.air_rounded,
    "Broken Footpath": Icons.directions_walk_rounded,
    "Tree Hazard": Icons.park_outlined,
    "Stray Animals": Icons.pets_rounded,
    "Electricity Issue": Icons.bolt_outlined,
    "Sewage Problem": Icons.plumbing_rounded,
    "Public Transport": Icons.directions_bus_filled_outlined,
    "Other": Icons.more_horiz_rounded,
  };

  // ===========================================================================
  // ORIGINAL LIFECYCLE / LOGIC — UNCHANGED (only the duplicate @override fixed)
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
    );

    if (picked != null) {
      setState(() {
        image = picked;
      });
    }
  }

  // Additive helper for the "Take Photo" button. Mirrors pickImage exactly,
  // only the ImageSource differs. Does not alter pickImage/upload logic.
  Future<void> _captureImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 20,
    );

    if (picked != null) {
      setState(() {
        image = picked;
      });
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        locationController.text = "Location services disabled";
        setState(() {});
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationController.text = "Permission denied";
        setState(() {});
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          locationController.text =
              "${place.locality ?? ''}, "
              "${place.administrativeArea ?? ''}, "
              "${place.country ?? ''}";
        } else {
          locationController.text =
              "${position.latitude}, ${position.longitude}";
        }
      } catch (_) {
        locationController.text = "${position.latitude}, ${position.longitude}";
      }

      setState(() {});
    } catch (e) {
      locationController.text = "Unable to fetch location";
      setState(() {});
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Original submit handler logic, preserved exactly — only wrapped with
  // isSubmitting flag updates for the loading animation on the new button.
  Future<void> _submitReport() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      String imageBase64 = '';

      if (image != null) {
        final bytes = await image!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      await FirebaseFirestore.instance.collection('issues').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'image': imageBase64,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'category': category,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Issue Reported Successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // ===========================================================================
  // ===========================  UI  =========================================
  // ===========================================================================

  // Premium colour palette
  static const Color _bgTop = Color(0xff030712);
  static const Color _bgMid = Color(0xff07111D);
  static const Color _bgBottom = Color(0xff0B1220);
  static const Color _surface = Color(0x0DFFFFFF); // white @ 5%
  static const Color _border = Color(0x14FFFFFF); // white @ 8%
  static const Color _primary = Color(0xff2563EB);
  static const Color _accent = Color(0xff3B82F6);
  static const Color _success = Color(0xff10B981);
  static const Color _gold = Color(0xffD4AF37);
  static const Color _secondaryText = Color(0xff94A3B8);

  // Staggered fade + slide-up wrapper for sections
  Widget _animated(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 1.0);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _pageController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  BoxDecoration _glassDecoration({double radius = 28}) {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  Widget _glassCard({
    required Widget child,
    double radius = 28,
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: _glassDecoration(radius: radius),
      child: child,
    );
  }

  // -------------------------------------------------------------------------
  // Background — soft mesh gradient + radial glows
  // -------------------------------------------------------------------------
  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgMid, _bgBottom],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _glow(_primary.withOpacity(0.18), 320),
        ),
        Positioned(
          top: 180,
          right: -140,
          child: _glow(_accent.withOpacity(0.12), 360),
        ),
        Positioned(
          bottom: -160,
          left: -60,
          child: _glow(_success.withOpacity(0.08), 320),
        ),
      ],
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Glass floating AppBar
  // -------------------------------------------------------------------------
  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _glassDecoration(radius: 22),
      child: Row(
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Report Issue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          // Small decorative progress indicator
          Container(
            width: 64,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.55,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_primary, _accent]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Hero section
  // -------------------------------------------------------------------------
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primary, _accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Report a Civic Issue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Help improve your city by reporting problems in real time.",
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _gold.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.groups_rounded, size: 14, color: _gold),
                      SizedBox(width: 6),
                      Text(
                        "Community Driven",
                        style: TextStyle(
                          color: _gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section heading helper
  // -------------------------------------------------------------------------
  Widget _sectionHeading(String number, String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(color: _secondaryText, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Image upload card
  // -------------------------------------------------------------------------
  Widget _buildImageCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            "1",
            "Upload Image",
            subtitle: "Add a clear image of the issue",
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            child:
                image == null ? _buildImagePlaceholder() : _buildImagePreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      key: const ValueKey("placeholder"),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_primary.withOpacity(0.25), _accent.withOpacity(0.1)],
              ),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Take Photo",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "or choose from gallery",
            style: TextStyle(color: _secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _outlinedActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: "Camera",
                  onTap: _captureImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _outlinedActionButton(
                  icon: Icons.image_outlined,
                  label: "Gallery",
                  onTap: pickImage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      key: const ValueKey("preview"),
      width: double.infinity,
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 240,
                  child:
                      kIsWeb
                          ? Image.network(image!.path, fit: BoxFit.cover)
                          : Image.file(File(image!.path), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _circleIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => setState(() => image = null),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _outlinedActionButton(
            icon: Icons.refresh_rounded,
            label: "Replace Image",
            onTap: pickImage,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _outlinedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 48,
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Premium text field
  // -------------------------------------------------------------------------
  Widget _premiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: maxLines > 1 ? 14 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
            child: Icon(icon, color: Colors.white38, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: maxLines > 1 ? 4 : 1,
              cursorColor: _accent,
              maxLength: maxLength,
              style: const TextStyle(color: Colors.white, fontSize: 15.5),
              decoration: InputDecoration(
                isDense: true,
                labelText: label,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                labelStyle: TextStyle(color: _secondaryText, fontSize: 13),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                border: InputBorder.none,
                counterText: "",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Issue details card (title + description)
  // -------------------------------------------------------------------------
  Widget _buildDetailsCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            "2",
            "Issue Details",
            subtitle: "Tell us what's wrong",
          ),
          _premiumField(
            controller: titleController,
            label: "Issue Title",
            hint: "e.g. Pothole on Main Road",
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 14),
          _premiumField(
            controller: descriptionController,
            label: "Description",
            hint: "Provide a clear description of the issue...",
            icon: Icons.notes_rounded,
            maxLines: 5,
            maxLength: 500,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: descriptionController,
              builder: (context, value, _) {
                return Text(
                  "${value.text.length}/500",
                  style: TextStyle(color: _secondaryText, fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Category chips — replaces the original dropdown, same `category` value
  // -------------------------------------------------------------------------
  Widget _buildCategoryCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            "3",
            "Select Category",
            subtitle: "Choose the issue type",
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categoryIcons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final entry = _categoryIcons.entries.elementAt(index);
                final isSelected = category == entry.key;

                return AnimatedScale(
                  scale: isSelected ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: () {
                          setState(() {
                            category = entry.key;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient:
                                isSelected
                                    ? const LinearGradient(
                                      colors: [_primary, _accent],
                                    )
                                    : null,
                            color:
                                isSelected
                                    ? null
                                    : Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : _border,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: _primary.withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.value,
                                size: 16,
                                color:
                                    isSelected ? Colors.white : Colors.white60,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                  fontSize: 13.5,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Location card
  // -------------------------------------------------------------------------
  Widget _buildLocationCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            "4",
            "Location",
            subtitle: "Where is this happening?",
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: locationController,
                  builder: (context, value, _) {
                    final hasLocation = value.text.trim().isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation ? value.text : "No location selected",
                          style: TextStyle(
                            color: hasLocation ? Colors.white : Colors.white38,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Tap below to detect or edit manually",
                          style: TextStyle(color: _secondaryText, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: getCurrentLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _accent.withOpacity(0.35)),
                  ),
                  child: const Text(
                    "Locate",
                    style: TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _premiumField(
            controller: locationController,
            label: "Location",
            hint: "e.g. Bandra West, Mumbai",
            icon: Icons.edit_location_alt_outlined,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // AI helper tip
  // -------------------------------------------------------------------------
  Widget _buildAiTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _success.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _success,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Helper Tip",
                  style: TextStyle(
                    color: _success,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Clear descriptions with accurate location help authorities resolve issues faster.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Submit button — premium gradient pill, preserves original onPressed logic
  // -------------------------------------------------------------------------
  Widget _buildSubmitButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: isSubmitting ? null : _submitReport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_primary, _accent],
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.4),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child:
              isSubmitting
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Submit Report",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Your report will make a difference",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Column(
              children: [
                _animated(0, _buildAppBar()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _animated(1, _buildHero()),
                          const SizedBox(height: 26),
                          _animated(2, _buildImageCard()),
                          const SizedBox(height: 18),
                          _animated(3, _buildDetailsCard()),
                          const SizedBox(height: 18),
                          _animated(4, _buildCategoryCard()),
                          const SizedBox(height: 18),
                          _animated(5, _buildLocationCard()),
                          const SizedBox(height: 18),
                          _animated(6, _buildAiTip()),
                          const SizedBox(height: 26),
                          _animated(7, _buildSubmitButton()),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
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
