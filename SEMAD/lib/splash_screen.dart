import 'dart:async';
import 'package:mathquest/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathquest/login.dart';

class MathQuestLoading extends StatefulWidget {
  const MathQuestLoading({super.key});

  @override
  State<MathQuestLoading> createState() => _MathQuestLoadingState();
}

class _MathQuestLoadingState extends State<MathQuestLoading> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  double _loadProgress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _run5SecondTimer();
  }

  void _run5SecondTimer() {
    // 5000ms / 100 steps = 50ms per step
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        if (_loadProgress >= 1.0) {
          timer.cancel();
          _handleNavigation();
        } else {
          _loadProgress += 0.01;
        }
      });
    });
  }

  void _handleNavigation() {
    // CHECK SUPABASE SESSION
    final session = Supabase.instance.client.auth.currentSession;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        // If session exists, go to Dashboard. Otherwise, Login.
        pageBuilder: (context, anim1, anim2) =>
        session != null ? const GanitControlCenter() : const MathQuestLogin(),
        transitionsBuilder: (context, anim1, anim2, child) =>
            FadeTransition(opacity: anim1, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color deepNavy = Color(0xFF000C2D);
    const Color softBlue = Color(0xFF80D8FF);

    return Scaffold(
      backgroundColor: deepNavy,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PULSING GRID ANIMATION
              const SpinKitPulsingGrid(
                color: softBlue,
                size: 100.0,
                boxShape: BoxShape.rectangle,
              ),

              const SizedBox(height: 100),

              // PROGRESS BAR SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _loadProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(softBlue),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "PREPARING YOUR QUEST",
                      style: GoogleFonts.lexend(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}