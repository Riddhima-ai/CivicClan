import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'HomePage.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Successful")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                )
                : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Deep dark navy base ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF050D1A),
                  Color(0xFF0A0E2A),
                  Color(0xFF07111D),
                ],
              ),
            ),
          ),

          // ── 2. Aurora / nebula glow blobs ──
          Positioned(
            top: -80,
            right: -60,
            child: _GlowBlob(
              size: 320,
              color: const Color(0xFF6D28D9).withOpacity(0.35),
            ),
          ),
          Positioned(
            top: 60,
            left: -80,
            child: _GlowBlob(
              size: 280,
              color: const Color(0xFF0EA5E9).withOpacity(0.20),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _GlowBlob(
              size: 260,
              color: const Color(0xFF7C3AED).withOpacity(0.25),
            ),
          ),
          Positioned(
            bottom: -60,
            right: 40,
            child: _GlowBlob(
              size: 220,
              color: const Color(0xFF2563EB).withOpacity(0.20),
            ),
          ),

          // ── 3. Decorative floating circles (like the reference image) ──
          // Top-left large bubble
          Positioned(
            top: 30,
            left: 20,
            child: _FloatingBubble(size: 110, opacity: 0.18),
          ),
          // Top-right medium bubble
          Positioned(
            top: 80,
            right: 30,
            child: _FloatingBubble(size: 75, opacity: 0.14),
          ),
          // Bottom-left medium bubble
          Positioned(
            bottom: 130,
            left: 10,
            child: _FloatingBubble(size: 90, opacity: 0.16),
          ),
          // Bottom-right small bubble
          Positioned(
            bottom: 200,
            right: 15,
            child: _FloatingBubble(size: 60, opacity: 0.14),
          ),
          // Small accent bubble mid-right
          Positioned(
            top: MediaQuery.of(context).size.height * 0.42,
            right: 8,
            child: _FloatingBubble(size: 45, opacity: 0.12),
          ),

          // ── 4. Star dots scattered ──
          const Positioned.fill(child: _StarField()),

          // ── 5. Card + content ──
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Container(
                        width: 420,
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.13),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6D28D9).withOpacity(0.18),
                              blurRadius: 50,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // City skyline icon
                            SizedBox(
                              width: 64,
                              height: 56,
                              child: CustomPaint(painter: _CityIconPainter()),
                            ),

                            const SizedBox(height: 16),

                            // Title
                            const Text(
                              "CIVIC CLAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Subtitle with bullet dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Dot(),
                                const SizedBox(width: 8),
                                Text(
                                  "Building Smarter Communities",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _Dot(),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Email field
                            _glassField(
                              controller: emailController,
                              hint: "Email Address",
                              icon: Icons.email_outlined,
                            ),

                            const SizedBox(height: 14),

                            // Password field
                            _glassField(
                              controller: passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 0,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // LOGIN button
                            Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6D28D9,
                                    ).withOpacity(0.45),
                                    blurRadius: 22,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              "LOGIN",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                letterSpacing: 2.5,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // OR
                            Text(
                              "OR",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // CREATE ACCOUNT button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "CREATE ACCOUNT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        letterSpacing: 1.8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.person_add_outlined,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom tagline
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.white.withOpacity(0.35),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Together for a better tomorrow",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12,
                          letterSpacing: 0.4,
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
}

// ── Glow blob ──
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.9,
            spreadRadius: size * 0.3,
          ),
        ],
      ),
    );
  }
}

// ── Translucent bubble (decorative circles from the reference) ──
class _FloatingBubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _FloatingBubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(opacity * 1.5),
          width: 1.2,
        ),
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity * 0.4),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

// ── Scattered star dots ──
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    final rng = Random(42);
    final size = MediaQuery.of(context).size;
    return CustomPaint(painter: _StarPainter(rng, size));
  }
}

class _StarPainter extends CustomPainter {
  final Random rng;
  final Size screenSize;
  _StarPainter(this.rng, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.3 + 0.3;
      paint.color = Colors.white.withOpacity(rng.nextDouble() * 0.5 + 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Purple dot for subtitle ──
class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: const BoxDecoration(
      color: Color(0xFF8B5CF6),
      shape: BoxShape.circle,
    ),
  );
}

// ── City skyline outline painter ──
class _CityIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF8B5CF6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    // Left short building
    path.moveTo(w * 0.05, h * 0.88);
    path.lineTo(w * 0.05, h * 0.55);
    path.lineTo(w * 0.20, h * 0.55);
    path.lineTo(w * 0.20, h * 0.88);

    // Left-mid taller building
    path.moveTo(w * 0.22, h * 0.88);
    path.lineTo(w * 0.22, h * 0.38);
    path.lineTo(w * 0.37, h * 0.38);
    path.lineTo(w * 0.37, h * 0.88);

    // Center tallest building with spire
    path.moveTo(w * 0.39, h * 0.88);
    path.lineTo(w * 0.39, h * 0.22);
    path.lineTo(w * 0.48, h * 0.06); // spire tip
    path.lineTo(w * 0.61, h * 0.22);
    path.lineTo(w * 0.61, h * 0.88);

    // Right-mid building
    path.moveTo(w * 0.63, h * 0.88);
    path.lineTo(w * 0.63, h * 0.42);
    path.lineTo(w * 0.78, h * 0.42);
    path.lineTo(w * 0.78, h * 0.88);

    // Right short building
    path.moveTo(w * 0.80, h * 0.88);
    path.lineTo(w * 0.80, h * 0.58);
    path.lineTo(w * 0.95, h * 0.58);
    path.lineTo(w * 0.95, h * 0.88);

    // Ground line
    path.moveTo(w * 0.02, h * 0.88);
    path.lineTo(w * 0.98, h * 0.88);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
