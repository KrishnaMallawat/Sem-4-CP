import 'package:flutter/material.dart';
import 'package:mathquest/supa.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathquest/ui_widgets.dart';
class SamaySudhaarGame extends StatefulWidget {
  const SamaySudhaarGame({super.key});
  @override
  State<SamaySudhaarGame> createState() => _SamaySudhaarGameState();
}

class _SamaySudhaarGameState extends State<SamaySudhaarGame> {
  int hour = 12, minute = 0, score = 0, currentQuestionIndex = 0;
  final int maxQuestions = 6;
  final Random _random = Random();
  final Color lexendNavy = const Color(0xFF000C2D), lexendYellow = const Color(0xFFFFE36B);

  List<Map<String, dynamic>> sessionRiddles = [];
  Map<String, dynamic>? currentRiddle;

  final List<Map<String, dynamic>> allRiddles = [
    {
      "riddle": "Set the clock to a 90° PERPENDICULAR angle at 9:00 AM.",
      "h": 9, "m": 0
    },
    {
      "riddle": "Form a 180° STRAIGHT LINE where the hands point opposite directions.",
      "h": 6, "m": 0
    },
    {
      "riddle": "Set the 'Victory' angle: An ACUTE angle between 10 and 11.",
      "h": 10, "m": 10
    },
    {
      "riddle": "Sync the hands: Both point to the exact START of a new day.",
      "h": 12, "m": 0
    },
    {
      "riddle": "Set a REFLEX angle where the minute hand is at 45 minutes past 12.",
      "h": 12, "m": 45
    },
    {
      "riddle": "Set the clock to HALF PAST FOUR: The hour hand is between 4 and 5.",
      "h": 4, "m": 30
    },
    {
      "riddle": "Set QUARTER PAST SIX: The minute hand is at 90° from the 12.",
      "h": 6, "m": 15
    }
  ];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      sessionRiddles = sessionRiddles = (List<Map<String, dynamic>>.from(allRiddles)..shuffle(_random)).take(maxQuestions).toList();
      score = 0; currentQuestionIndex = 0; _loadRiddle();
    });
  }

  void _loadRiddle() {
    setState(() { currentRiddle = sessionRiddles[currentQuestionIndex]; hour = 12; minute = 0; });
  }

  void _changeTime({int h = 0, int m = 0}) {
    setState(() {
      hour = (hour + h + 12) % 12; if (hour == 0) hour = 12;
      minute = (minute + m + 60) % 60;
    });
  }

  void _checkAnswer() {
    bool correct = (hour == currentRiddle!["h"] && minute == currentRiddle!["m"]);
    if (correct) score += 10;
    _showResult(correct);
  }

  void _showResult(bool correct) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: lexendNavy,
        shape: RoundedRectangleBorder(side: BorderSide(color: lexendYellow)),
        title: Text(correct ? 'SYNCED ✅' : 'FAILED ❌', style: GoogleFonts.lexend(color: lexendYellow)),
        actions: [ElevatedButton(onPressed: () { Navigator.pop(ctx); _next(); }, child: const Text("NEXT"))],
      ),
    );
  }

  void _next() {
    if (++currentQuestionIndex < maxQuestions) {_loadRiddle();} else {_showFinal();}
  }

  void _showFinal() async {
    // SAVE XP
    if (score > 0) {
      try {
        await Supabase.instance.client.rpc('increment_xp', params: {'amount': score});
        await SupaService.saveGameSession(gameName: 'Quick Tick', score: score, timeSpentSeconds: 60);
      } catch (e) {
        debugPrint("Failed to save XP: $e");
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: lexendNavy,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: lexendYellow, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "MISSION COMPLETE",
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            color: lexendYellow,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("FINAL NEURON SCORE",
                style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 10),
            Text(
              "$score / ${maxQuestions * 10}",
              style: GoogleFonts.lexend(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              // PRIMARY ACTION: REPLAY
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lexendYellow,
                    foregroundColor: lexendNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startGame();
                  },
                  child: Text("REBOOT SESSION", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              // SECONDARY ACTION: EXIT
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  Navigator.pop(context); // Exit Game Screen
                },
                child: Text(
                  "EXIT TO HUB",
                  style: GoogleFonts.lexend(
                    color: Colors.white24,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return a loader if the riddle hasn't initialized yet
    if (currentRiddle == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: lexendNavy,
      body: Stack(
        children: [
          // --- LAYER 1: BACKGROUND IMAGE ---
          Positioned.fill(
            child: Image.asset(
              'assets/clock_bg.png', // Ensure this exists in your pubspec.yaml
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: lexendNavy),
            ),
          ),

          // --- LAYER 2: THEMED OVERLAYS ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lexendNavy.withOpacity(0),
                    lexendNavy.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: GridPainter())),

          // --- LAYER 3: UI CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                children: [
                  // CENTERED HUD SECTION
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _hud("MISSION", "${currentQuestionIndex + 1} / $maxQuestions"),
                      const SizedBox(width: 50),
                      _hud("NEURON SCORE", "$score"),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // RIDDLE BOX
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: lexendYellow.withOpacity(0.4), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: lexendYellow.withOpacity(0.05),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: Text(
                      currentRiddle!["riddle"],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // CLOCK VISUALIZATION (Fixed Size for Single Page)
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: ClockPainter(hour, minute, lexendYellow),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // CONTROL GRID
                  Row(
                    children: [
                      _controlBtn("- 1 HOUR", () => _changeTime(h: -1)),
                      const SizedBox(width: 12),
                      _controlBtn("+ 1 HOUR", () => _changeTime(h: 1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _controlBtn("- 5 MIN", () => _changeTime(m: -5)),
                      const SizedBox(width: 12),
                      _controlBtn("+ 5 MIN", () => _changeTime(m: 5)),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // FINAL SUBMIT ACTION
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lexendYellow,
                        foregroundColor: lexendNavy,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _checkAnswer,
                      child: Text(
                        "SUBMIT",
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REFINED UI HELPERS ---

  Widget _hud(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(color: Colors.white38, fontSize: 10),
        ),
        Text(
          value,
          style: GoogleFonts.lexend(
            color: lexendYellow,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _controlBtn(String label, VoidCallback onPress) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
            backgroundColor: Colors.white.withOpacity(0.01),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onPress,
          child: Text(
            label,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlRow(String t1, String t2, VoidCallback f1, VoidCallback f2) => Row(
    children: [
      Expanded(child: OutlinedButton(onPressed: f1, child: Text(t1, style: const TextStyle(color: Colors.white)))),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton(onPressed: f2, child: Text(t2, style: const TextStyle(color: Colors.white)))),
    ],
  );
}

class ClockPainter extends CustomPainter {
  final int h, m; final Color acc;
  ClockPainter(this.h, this.m, this.acc);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2); final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = Colors.white10);
    canvas.drawCircle(c, r, Paint()..color = acc..style = PaintingStyle.stroke..strokeWidth = 3);
    for (int i = 0; i < 12; i++) {
      final a = (i * 30 - 90) * pi / 180;
      canvas.drawLine(c + Offset(cos(a) * r * 0.85, sin(a) * r * 0.85), c + Offset(cos(a) * r * 0.95, sin(a) * r * 0.95), Paint()..color = i % 3 == 0 ? acc : Colors.white24 ..strokeWidth = i % 3 == 0 ? 3.0 : 3.0);
    }
    final ha = ((h % 12) * 30 + (m * 0.5) - 90) * pi / 180;
    final ma = (m * 6 - 90) * pi / 180;
    canvas.drawLine(c, c + Offset(cos(ha) * r * 0.5, sin(ha) * r * 0.5), Paint()..color = Colors.white..strokeWidth = 6..strokeCap = StrokeCap.round);
    canvas.drawLine(c, c + Offset(cos(ma) * r * 0.75, sin(ma) * r * 0.75), Paint()..color = acc..strokeWidth = 4..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, 4, Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => true;
}
