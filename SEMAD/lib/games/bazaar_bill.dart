import 'package:flutter/material.dart';
import 'package:mathquest/supa.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:mathquest/main.dart';

class BazaarBillGame extends StatefulWidget {
  const BazaarBillGame({super.key});

  @override
  State<BazaarBillGame> createState() => _BazaarBillGameState();
}

class _BazaarBillGameState extends State<BazaarBillGame> {
  bool _isLoading = true;
  int step = 1;
  int totalBill = 0;
  int cashGiven = 500;
  int changeReturned = 0;
  final TextEditingController _totalController = TextEditingController();
  int customersServed = 0;
  int secondsRemaining = 240;
  Timer? _gameTimer;

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _generateNewCustomer();
    _startTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _totalController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        timer.cancel();
        _showFinalResults();
      }
    });
  }

  int sessionXP = 0;
  int streak = 0;
  DateTime? customerStartTime;

  double difficultyMultiplier = 1.0;

  void _generateNewCustomer() {
    final random = Random();
    customerStartTime = DateTime.now();

    final List<Map<String, dynamic>> catalog = [
      {"name": "GEL PEN", "min": 10, "max": 28},
      {"name": "NOTEBOOK", "min": 45, "max": 75},
      {"name": "POTATO CHIPS", "min": 15, "max": 32},
      {"name": "OIL PASTELS", "min": 85, "max": 145},
      {"name": "LEGO", "min": 120, "max": 259},
      {"name": "BATTERIES", "min": 35, "max": 95},
      {"name": "STORY BOOK", "min": 155, "max": 299},
      {"name": "GEOMETRY BOX", "min": 115, "max": 195},
      {"name": "CHOCOLATE", "min": 10, "max": 100},
    ];

    // 2. DYNAMIC ITEM COUNT
    int itemCount = (2 + (difficultyMultiplier * 1.5).toInt()).clamp(2, 6);
    catalog.shuffle();

    items = List.generate(itemCount, (i) {
      var product = catalog[i];
      int price = product['min'] + random.nextInt(product['max'] - product['min']);
      return {"name": product['name'], "price": price};
    });

    totalBill = items.fold(0, (sum, item) => sum + (item['price'] as int));

    if (totalBill < 100) {
      cashGiven = 100;
    } else if (totalBill < 200) {
      cashGiven = 200;
    } else if (totalBill < 300) {
      cashGiven = 300;
    } else if (totalBill < 500) {
      cashGiven = 500;
    } else {
      cashGiven = ((totalBill / 100).ceil() * 100);
    }

    _totalController.clear();
    changeReturned = 0;
    step = 1;
  }

  void _verifyTotal() {
    if (int.tryParse(_totalController.text) == totalBill) {
      setState(() => step = 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("INCORRECT TOTAL!"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _addChange(int amount) => setState(() => changeReturned += amount);
  void _resetChange() => setState(() => changeReturned = 0);

  void _submitChange() async {
    if (changeReturned == (cashGiven - totalBill)) {
      final timeTaken = DateTime.now().difference(customerStartTime!).inSeconds;
      bool leveledUp = false;

      setState(() {
        double oldMultiplier = difficultyMultiplier;
        if (timeTaken < 12) {
          difficultyMultiplier = (difficultyMultiplier + 0.25).clamp(1.0, 3.0);
          if (oldMultiplier < 2.0 && difficultyMultiplier >= 2.0) leveledUp = true;
        } else if (timeTaken > 22) {
          difficultyMultiplier = (difficultyMultiplier - 0.2).clamp(1.0, 3.0);
        }
      });

      if (leveledUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔥 DIFFICULT LEVEL UNLOCKED! +5 XP BONUS ACTIVE"),
            backgroundColor: Color(0xFFFFC741), // Your themeYellow
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 2. XP & Streak Logic
      int earnedXP = 10; // Base XP

      if (timeTaken < 10) earnedXP += 5;

      if (difficultyMultiplier >= 2.0) {
        earnedXP += 5; // Add 5XP for passing difficult level
      }
      streak++;
      if (streak % 3 == 0) {
        earnedXP = (earnedXP * 1.5).toInt(); // Streak Multiplier
      }

      // 3. Push to Supabase
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          // This replaces the select and update calls with one line
          await supabase.rpc('increment_xp', params: {'amount': earnedXP});

          sessionXP += earnedXP;
        }
      } catch (e) {
        debugPrint("DB Error: $e");
      }

      setState(() => customersServed++);
      _showSuccessDialog();
    } else {
      // Heavy vibration for error
      HapticFeedback.heavyImpact();
      setState(() => streak = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WRONG CHANGE!"), backgroundColor: Colors.orangeAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (secondsRemaining ~/ 60).toString();
    String seconds = (secondsRemaining % 60).toString().padLeft(2, '0');

      if (_isLoading) {
        return GameLoader(onComplete: () {
          setState(() => _isLoading = false);
        });
      }

    return Scaffold(
      backgroundColor: const Color(0xFF00195A),
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              'assets/BAZAARBILL.png',
              fit: BoxFit.cover, // Ensures image fills the screen
            ),
          ),

          // --- DIGITAL TIMER (Overlay) ---
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$minutes:$seconds",
                style: GoogleFonts.shareTechMono(
                  color: secondsRemaining < 30 ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 340,
              height: 500,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.9),
                    blurRadius: 10,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: step == 1 ? _buildBillingPhase() : _buildChangePhase(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Text("RECEIPT #0892",
                    style: GoogleFonts.courierPrime(color: Colors.white, fontSize: 18, letterSpacing: 2)),
                const Divider(color: Colors.white38, height: 20, thickness: 0.5),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white30, height: 12, thickness: 0.5),
                    itemBuilder: (context, index) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(items[index]['name'], style: GoogleFonts.courierPrime(color: Colors.white70, fontSize: 18)),
                        Text("₹${items[index]['price']}", style: GoogleFonts.courierPrime(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // Aligns label and box vertically
            children: [
              const Text(" TOTAL",
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w500, fontSize: 15)),
              Container(
                width: 90,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TextField(
                  controller: _totalController,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center, // CRITICAL for vertical alignment
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _verifyTotal(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.0, // Force line height to match font size
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,      // Removes ALL internal padding/margins
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _btn("CANCEL", const Color(0xFF383838), () => Navigator.pop(context)),
            const SizedBox(width: 10),
            _btn("PROCEED", const Color(0xFF254FBD), _verifyTotal),
          ],
        )
      ],
    );
  }

  Widget _buildChangePhase() {
    // 1. Map the value (int) to the local asset path (String)
    final Map<int, String> currencyAssets = {
      1: 'assets/currency/1.png',
      2: 'assets/currency/2.png',
      5: 'assets/currency/5.png',
      10: 'assets/currency/10.png',
      20: 'assets/currency/20.png',
      50: 'assets/currency/50.png',
      100: 'assets/currency/100.png',
      200: 'assets/currency/200.png',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
          child: Column(
            children: [
              Text("CASH RECEIVED: ₹$cashGiven", style: GoogleFonts.courierPrime(color: Colors.greenAccent, fontSize: 16)),
              const SizedBox(height: 10),
              Text("₹$changeReturned", style: GoogleFonts.courierPrime(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              Text("RETURN CHANGE", style: GoogleFonts.courierPrime(color: Colors.white24, fontSize: 15)),
              Text("(Total : ₹$totalBill)", style: GoogleFonts.courierPrime(color: Colors.white38, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 20), // Reduced height as images provide visual space
        Expanded(
          child: Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.center,
            // 2. Iterate through the asset map keys (the values)
            children: currencyAssets.keys.map((n) => InkWell(
              onTap: () {
                HapticFeedback.lightImpact(); // Makes tapping the note feel "tactile"
                _addChange(n);
              },
              child: Container(
                // 3. Adjusted dimensions to look better with note images
                width: 90, // Slightly wider for notes
                height: 50, // Slightly taller
                decoration: BoxDecoration(
                  // Minimal styling, the image should be the focus
                  color: Colors.transparent,
                  // Useful during debugging to see touch areas
                  // border: Border.all(color: Colors.white10),
                ),
                // 4. Load the specific image using BoxFit.contain
                child: Image.asset(
                  currencyAssets[n]!, // Look up the path based on the value 'n'
                  fit: BoxFit.contain, // Ensures the whole note is visible
                ),
              ),
            )).toList(),
          ),
        ),
        Row(
          children: [
            _btn("RESET", Colors.redAccent.withOpacity(0.1), _resetChange, tColor: Colors.redAccent),
            const SizedBox(width: 10),
            _btn("FINISH", Colors.green, _submitChange),
          ],
        )
      ],
    );
  }

  Widget _btn(String txt, Color c, VoidCallback tap, {Color tColor = Colors.white}) {
    return Expanded(
      child: InkWell(
        onTap: tap,
        child: Container(
          height: 45,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
          child: Center(child: Text(txt, style: TextStyle(color: tColor, fontWeight: FontWeight.bold, fontSize: 12))),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    SettingsService.triggerHaptic(HapticType.success);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Auto-close logic: Wait 2 seconds, then pop and generate new customer
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // Close Dialog
            setState(() => _generateNewCustomer()); // Start next round automatically
          }
        });

        return Dialog(
          backgroundColor: const Color(0xFF303134),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SmoothBlipAnimation(),
                SizedBox(height: 30),
                Text(
                  "CORRECT",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "NEXT CUSTOMER ARRIVING",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFinalResults() {
    SupaService.saveGameSession(
      gameName: 'Bazaar Bill',
      score: sessionXP,
      timeSpentSeconds: 240,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF000C2D), // Matching your deepNavy
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Matching your squared-off preference
          side: const BorderSide(color: Color(0xFFFFC741), width: 1), // Yellow accent border
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "QUEST COMPLETE",
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: const Color(0xFFFFC741),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 25),

              // --- RPG LOOT BOX ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _statRow("CUSTOMERS", "$customersServed"),
                    const Divider(color: Colors.white10, height: 20),
                    _statRow("TOTAL XP", "+$sessionXP"), // Shows actual XP earned this session
                    const Divider(color: Colors.white10, height: 20),
                    _statRow("BEST STREAK", "$streak"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- EXIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC741),
                    foregroundColor: const Color(0xFF000C2D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    "COLLECT REWARDS",
                    style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
            label,
            style: GoogleFonts.lexend(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w500
            )
        ),
        Text(
            value,
            style: GoogleFonts.lexend(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18
            )
        ),
      ],
    );
  }

}

// --- ANIMATION COMPONENTS (Kept from your original logic) ---

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: CustomPaint(
          size: const Size(120, 120),
          painter: SuccessTickPainter(checkPercentage: _checkAnimation.value, accentColor: const Color(0xFF46A358)),
        ),
      ),
    );
  }
}

class SuccessTickPainter extends CustomPainter {
  final double checkPercentage;
  final Color accentColor;
  SuccessTickPainter({required this.checkPercentage, required this.accentColor});

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
  bool shouldRepaint(SuccessTickPainter oldDelegate) => oldDelegate.checkPercentage != checkPercentage;
}

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
    // Simulate loading time (2.5 seconds)
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.02;
        } else {
          _timer?.cancel();
          widget.onComplete(); // Launch the game
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
      backgroundColor: const Color(0xFF000C2D), // Your Deep Navy
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game Specific Icon
            // 1. YOUR GAME-SPECIFIC ICON/IMAGE
            // We can reuse one of your main game images for simplicity
            Image.asset(
              'assets/BAAZAR BILL LOAD.png', // Or 'assets/drawer.png' for a larger effect
              height: 350, // Keep it from overwhelming the screen
              width: 350,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              "SETTING UP SHOP",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // Progress Bar
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
                    color: const Color(0xFFFFC741), // Theme Yellow
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