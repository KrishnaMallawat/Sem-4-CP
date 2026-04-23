import 'package:flutter/material.dart';
import 'package:mathquest/supa.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormulaFlashGame extends StatefulWidget {
  const FormulaFlashGame({super.key});

  @override
  State<FormulaFlashGame> createState() => _FormulaFlashGameState();
}

class _FormulaFlashGameState extends State<FormulaFlashGame> {
  // --- LOADING STATE ---
  bool _isLoading = true;

  final List<String> _data = [
    'Square Area', 's²',
    'Circle Area', 'πr²',
    'Cube Volume', 's³',
    'Rectangle Area', 'l × w',
    'Sphere SA', '4πr²',
    'Cuboid Volume', 'l × w × h',
  ];

  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _firstIndex;
  DateTime? _gameStartTime;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _cards = List.from(_data)..shuffle();
      _flipped = List.generate(_cards.length, (_) => false);
      _matched = List.generate(_cards.length, (_) => false);
      _firstIndex = null;
      _isBusy = false;
      _gameStartTime = DateTime.now();
    });
  }

  void _onTap(int index) {
    if (_isBusy || _flipped[index] || _matched[index]) return;
    setState(() => _flipped[index] = true);
    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _checkMatch(_firstIndex!, index);
    }
  }

  void _handleWin() async {
    final timeTaken = DateTime.now().difference(_gameStartTime!).inSeconds;

    int earnedXP = 10;
    if (timeTaken < 20) {
      earnedXP += 10;
    } else if (timeTaken < 40) {
      earnedXP += 5;
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.rpc('increment_xp', params: {'amount': earnedXP});
        await SupaService.saveGameSession(gameName: 'Formula Flash', score: earnedXP, timeSpentSeconds: timeTaken);
      }
    } catch (e) {
      debugPrint("Supabase XP Sync Error: $e");
    }

    _showWinDialog(earnedXP, timeTaken);
  }

  void _checkMatch(int i1, int i2) {
    _isBusy = true;
    bool isMatch = (_data.indexOf(_cards[i1]) ~/ 2) == (_data.indexOf(_cards[i2]) ~/ 2);

    Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          if (isMatch) {
            _matched[i1] = _matched[i2] = true;
            if (_matched.every((m) => m == true)) {
              _handleWin();
            }
          } else {
            _flipped[i1] = _flipped[i2] = false;
          }
          _firstIndex = null;
          _isBusy = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- INTEGRATED LOADER ---
    if (_isLoading) {
      return GameLoader(onComplete: () {
        setState(() {
          _isLoading = false;
          _gameStartTime = DateTime.now(); // Restart timer after loading
        });
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00195A), Color(0xFF000C2D)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, i) => _buildCard(i),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 90, top: 0),
              child: Center(
                child: _actionButton(
                    "RESET BOARD",
                    Colors.white.withOpacity(0.1),
                    _resetGame
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---
  Widget _buildCard(int i) {
    bool isVisible = _flipped[i] || _matched[i];
    return GestureDetector(
      onTap: () => _onTap(i),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isVisible ? pi : 0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutBack,
        builder: (context, rotationValue, _) {
          bool isBack = rotationValue >= (pi / 2);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(rotationValue),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
                image: !isBack
                    ? const DecorationImage(
                  image: AssetImage('assets/card.png'),
                  fit: BoxFit.cover,
                )
                    : null,
                color: isBack
                    ? (_matched[i] ? const Color(0xFF46A358) : Colors.white)
                    : const Color(0xFF1A237E),
              ),
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(isBack ? pi : 0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      isBack ? _cards[i] : "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isBack ? Colors.black87 : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback action) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
        ),
      ),
    );
  }

  void _showWinDialog(int xp, int seconds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF000C2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFC741), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SmoothBlipAnimation(),
              const SizedBox(height: 20),
              Text(
                "+$xp XP EARNED",
                style: GoogleFonts.lexend(color: const Color(0xFFFFC741), fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text("COMPLETED IN $seconds SECONDS", style: GoogleFonts.lexend(color: Colors.white60, fontSize: 14)),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton("EXIT", Colors.white10, () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }),
                  const SizedBox(width: 12),
                  _actionButton("PLAY AGAIN", const Color(0xFF254FBD), () {
                    Navigator.pop(context);
                    _resetGame();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- LOADER COMPONENT ---
class GameLoader extends StatefulWidget {
  final VoidCallback onComplete;
  const GameLoader({super.key, required this.onComplete});

  @override
  State<GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<GameLoader> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.02;
        } else {
          _timer?.cancel();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000C2D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/FORMULA FLASH LOAD.png', // Ensure this exists in assets
              height: 350,
              width: 350,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              "SHUFFLING FORMULAS",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 250,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: UnconstrainedBox(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: 250 * _progress,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC741),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ANIMATION PAINTERS ---
class FormulaFlashPainter extends CustomPainter {
  final double checkPercentage;
  final Color accentColor;
  FormulaFlashPainter({required this.checkPercentage, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, Paint()..color = accentColor);
    final paint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(size.width * 0.28, size.height * 0.53);
    path.lineTo(size.width * 0.46, size.height * 0.68);
    path.lineTo(size.width * 0.76, size.height * 0.38);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0.0, metric.length * checkPercentage), paint);
    }
  }
  @override
  bool shouldRepaint(FormulaFlashPainter oldDelegate) => oldDelegate.checkPercentage != checkPercentage;
}

class SmoothBlipAnimation extends StatefulWidget {
  const SmoothBlipAnimation({super.key});
  @override
  State<SmoothBlipAnimation> createState() => _SmoothBlipAnimationState();
}

class _SmoothBlipAnimationState extends State<SmoothBlipAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)));
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn)));
    _controller.forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: CustomPaint(
          size: const Size(120, 120),
          painter: FormulaFlashPainter(checkPercentage: _checkAnimation.value, accentColor: const Color(0xFF254FBD)),
        ),
      ),
    );
  }
}