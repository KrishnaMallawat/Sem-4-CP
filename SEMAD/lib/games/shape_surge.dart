import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// --- MODELS ---
enum ShapeType { circle, square, triangle, pentagon, rectangle, scalene, sector, arc, rightTriangle }

class FallingShape {
  final String id;
  double x, y, dy;
  final ShapeType type;
  final Color color;
  bool isSliced = false;

  FallingShape({
    required this.id, required this.x, required this.y,
    required this.dy, required this.type, required this.color,
  });

  bool contains(Offset point) =>
      point.dx >= x && point.dx <= x + 80 && point.dy >= y && point.dy <= y + 80;
}

class ShapeRiddle {
  final String riddle;
  final bool Function(ShapeType) check;
  ShapeRiddle({required this.riddle, required this.check});
}

class MathShapeNinjaGame extends StatefulWidget {
  const MathShapeNinjaGame({super.key});
  @override
  State<MathShapeNinjaGame> createState() => _MathShapeNinjaGameState();
}

class _MathShapeNinjaGameState extends State<MathShapeNinjaGame> with SingleTickerProviderStateMixin {
  int score = 0;
  int timeLeft = 60;
  int startTimer = 5;
  bool isCountingDown = true;
  bool isGameOver = false;

  Timer? gameLoop;
  Timer? spawnTimer;
  Timer? clockTimer;

  List<FallingShape> shapes = [];
  List<Offset> _bladeTrail = [];
  double _shake = 0.0;
  final Random random = Random();

  late AnimationController _glowController;
  late Animation<Color?> _backgroundColor;

  // --- THEMED COLORS ---
  final Color lexendNavy = const Color(0xFF000C2D);
  final Color lexendYellow = const Color(0xFFFFE36B);

  // --- REFINED RIDDLE BANK ---
  final List<ShapeRiddle> riddleBank = [
    ShapeRiddle(riddle: "Slice the SCALENE Triangle!", check: (t) => t == ShapeType.scalene),
    ShapeRiddle(riddle: "Find the MAJOR SECTOR! (> 180°)", check: (t) => t == ShapeType.sector),
    ShapeRiddle(riddle: "Catch the ARC! (Curve segment)", check: (t) => t == ShapeType.arc),
    ShapeRiddle(riddle: "Slice the RIGHT-ANGLED Triangle!", check: (t) => t == ShapeType.rightTriangle),
    ShapeRiddle(riddle: "Find the shape with a HYPOTENUSE!", check: (t) => t == ShapeType.rightTriangle),
    ShapeRiddle(riddle: "Catch the Convex PENTAGON!", check: (t) => t == ShapeType.pentagon),
    ShapeRiddle(riddle: "Find the Non-Square Quadrilateral!", check: (t) => t == ShapeType.rectangle),
  ];

  late ShapeRiddle currentRiddle;

  @override
  void initState() {
    super.initState();
    currentRiddle = riddleBank[random.nextInt(riddleBank.length)];
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _backgroundColor = ColorTween(
      begin: lexendNavy,
      end: lexendYellow.withOpacity(0.3),
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _startPreGame();
  }

  void _startPreGame() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (startTimer > 1) {
          startTimer--;
        } else {
          t.cancel();
          isCountingDown = false;
          _startActiveGame();
        }
      });
    });
  }

  void _startActiveGame() {
    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!mounted) return;
      setState(() {
        for (var s in shapes) { s.y += s.dy; s.dy += 0.10; }
        shapes.removeWhere((s) => s.y > MediaQuery.of(context).size.height + 100);
        if (_shake > 0) _shake -= 0.6;
      });
    });

    spawnTimer = Timer.periodic(const Duration(milliseconds: 270), (t) => _spawnShape());

    clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
          if (timeLeft % 10 == 0 && timeLeft != 0) _triggerRiddleShift();
        });
      } else {
        t.cancel();
        _endGame();
      }
    });
  }

  void _triggerRiddleShift() {
    _glowController.forward().then((_) => _glowController.reverse());
    setState(() => currentRiddle = riddleBank[random.nextInt(riddleBank.length)]);
  }

  void _spawnShape() {
    double sw = MediaQuery.of(context).size.width;

    // --- LOGIC: EXACTLY 30% CHANCE FOR CORRECT ANSWER ---
    ShapeType spawnedType;
    bool shouldBeCorrect = random.nextDouble() < 0.30;

    if (shouldBeCorrect) {
      List<ShapeType> validTypes = ShapeType.values.where((t) => currentRiddle.check(t)).toList();
      spawnedType = validTypes[random.nextInt(validTypes.length)];
    } else {
      List<ShapeType> invalidTypes = ShapeType.values.where((t) => !currentRiddle.check(t)).toList();
      spawnedType = invalidTypes[random.nextInt(invalidTypes.length)];
    }

    setState(() {
      shapes.add(FallingShape(
        id: UniqueKey().toString(),
        x: 40 + random.nextDouble() * (sw - 100),
        y: -100,
        dy: 1.2 + random.nextDouble() * 1.8,
        type: spawnedType,
        color: [Colors.pinkAccent, Colors.cyanAccent, Colors.purpleAccent, Colors.orangeAccent, Colors.greenAccent][random.nextInt(5)],
      ));
    });
  }

  void _handleSlice(Offset pos) {
    if (isCountingDown || isGameOver) return;
    for (int i = 0; i < shapes.length; i++) {
      var s = shapes[i];
      if (!s.isSliced && s.contains(pos)) {
        setState(() {
          s.isSliced = true;
          if (currentRiddle.check(s.type)) {
            score += 50;
          } else {
            score = max(0, score - 30);
            _shake = 15.0;
          }
        });
      }
    }
    setState(() => shapes.removeWhere((s) => s.isSliced));
  }

  void _endGame() async {
    gameLoop?.cancel(); spawnTimer?.cancel(); clockTimer?.cancel();
    setState(() => isGameOver = true);

    // SAVE XP
    if (score > 0) {
      try {
        await Supabase.instance.client.rpc('increment_xp', params: {'amount': score});
      } catch (e) {
        debugPrint("Failed to save XP: $e");
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    gameLoop?.cancel(); spawnTimer?.cancel(); clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundColor,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColor.value,
          body: GestureDetector(
            onPanUpdate: (d) {
              setState(() {
                _bladeTrail.add(d.localPosition);
                if (_bladeTrail.length > 8) _bladeTrail.removeAt(0);
              });
              _handleSlice(d.localPosition);
            },
            onPanEnd: (_) => setState(() => _bladeTrail = []),
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statBox("SCORE", "$score", lexendYellow),
                            _statBox("TIME", "$timeLeft", Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentRiddle.riddle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          color: lexendYellow,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                ...shapes.map((s) => Positioned(left: s.x, top: s.y, child: CustomPaint(size: const Size(80, 80), painter: MasterGeometryPainter(s.type, s.color, lexendYellow)))),
                CustomPaint(size: Size.infinite, painter: TrailPainter(_bladeTrail, lexendYellow)),
                if (isCountingDown) _overlay("GET READY", currentRiddle.riddle, "$startTimer"),
                if (isGameOver) _gameOverScreen(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statBox(String l, String v, Color c) => Column(children: [
    Text(l, style: GoogleFonts.lexend(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
    Text(v, style: GoogleFonts.lexend(color: c, fontSize: 32, fontWeight: FontWeight.w900)),
  ]);

  Widget _overlay(String t1, String t2, String t3) => Container(
    color: lexendNavy.withOpacity(0.95), width: double.infinity, height: double.infinity,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(t1, style: GoogleFonts.lexend(color: Colors.white30, fontSize: 20, letterSpacing: 4)),
      Padding(padding: const EdgeInsets.all(40), child: Text(t2, textAlign: TextAlign.center, style: GoogleFonts.lexend(color: lexendYellow, fontSize: 32, fontWeight: FontWeight.bold))),
      Text(t3, style: GoogleFonts.lexend(color: Colors.white, fontSize: 120, fontWeight: FontWeight.w900)),
    ]),
  );

  Widget _gameOverScreen() => Container(
    color: lexendNavy, width: double.infinity, height: double.infinity,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("GAME OVER", style: GoogleFonts.lexend(color: lexendYellow, fontSize: 48, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Text("SCORE: $score", style: GoogleFonts.lexend(color: Colors.white, fontSize: 36)),
      const SizedBox(height: 60),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: lexendYellow, foregroundColor: lexendNavy, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20)),
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MathShapeNinjaGame())),
          child: Text("PLAY AGAIN", style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 18))),
      const SizedBox(height: 20),
      TextButton(onPressed: () => Navigator.pop(context), child: Text("EXIT", style: GoogleFonts.lexend(color: Colors.white30, fontSize: 18))),
    ]),
  );
}

// --- MASTER GEOMETRY PAINTER ---
class MasterGeometryPainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  final Color yellowAccent;
  MasterGeometryPainter(this.type, this.color, this.yellowAccent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final paint = Paint()..shader = RadialGradient(colors: [color.withOpacity(0.7), color], center: const Alignment(-0.3, -0.3), radius: 0.8).createShader(Offset.zero & size);
    final markerPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;

    switch (type) {
      case ShapeType.sector:
        canvas.drawArc(Offset.zero & size, 0.5, 5.0, true, paint);
        break;
      case ShapeType.arc:
        canvas.drawArc(Offset.zero & size, 0.5, 3.5, false, markerPaint..strokeWidth = 6..color = Colors.white70);
        break;
      case ShapeType.rightTriangle:
        var path = Path()..moveTo(w*0.1, h*0.1)..lineTo(w*0.1, h*0.9)..lineTo(w*0.9, h*0.9)..close();
        canvas.drawPath(path, paint);
        // Highlight Hypotenuse in Yellow
        canvas.drawLine(Offset(w*0.1, h*0.1), Offset(w*0.9, h*0.9), markerPaint..color = yellowAccent..strokeWidth = 4);
        break;
      case ShapeType.scalene:
        var path = Path()..moveTo(w*0.4, h*0.1)..lineTo(w*0.9, h*0.8)..lineTo(w*0.1, h*0.9)..close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.circle:
        canvas.drawCircle(Offset(w/2, h/2), w/2, paint);
        break;
      case ShapeType.pentagon:
        _drawPolygon(canvas, paint, w, h, 5);
        break;
      case ShapeType.rectangle:
        canvas.drawRRect(RRect.fromLTRBR(w*0.1, h*0.35, w*0.9, h*0.65, const Radius.circular(4)), paint);
        break;
      default:
        canvas.drawCircle(Offset(w/2, h/2), w/2, paint);
    }
    // Gloss highlight
    canvas.drawCircle(Offset(w*0.3, h*0.3), 6, Paint()..color = Colors.white24..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  void _drawPolygon(Canvas canvas, Paint paint, double w, double h, int sides) {
    var path = Path(); double angle = (2 * pi) / sides;
    for (int i = 0; i < sides; i++) {
      double x = w/2 + w/2 * cos(i * angle - pi/2);
      double y = h/2 + h/2 * sin(i * angle - pi/2);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path..close(), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrailPainter extends CustomPainter {
  final List<Offset> pts; final Color trailColor;
  TrailPainter(this.pts, this.trailColor);
  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    canvas.drawPath(Path()..addPolygon(pts, false), Paint()..color = trailColor..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}