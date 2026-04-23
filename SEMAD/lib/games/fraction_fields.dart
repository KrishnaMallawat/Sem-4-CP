import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mathquest/supa.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FractionApp extends StatelessWidget {
  const FractionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameScreen();
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // --- ADDED LOADING STATE ---
  bool _isLoading = true;

  int currentQuestion = 1;
  final int totalQuestions = 5;

  late int multiplicand, correctAnswer;
  late String equationText;
  Set<int> harvestedIndices = {};

  final Color softBlue = const Color(0xFF80D8FF);
  final Color deepNavy = const Color(0xFF000C2D);

  double _timerValue = 1.0;
  Timer? _countdownTimer;
  int _secondsRemaining = 20;

  @override
  void initState() {
    super.initState();
    generateQuestion();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startHarvestTimer() {
    _countdownTimer?.cancel();
    _timerValue = 1.0;
    _secondsRemaining = 30;

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timerValue > 0) {
          _timerValue -= (0.1 / 30.0);
          if (timer.tick % 10 == 0) _secondsRemaining--;
        } else {
          _timerValue = 0;
          timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    _showFailureDialog("SUNSET!", "The sun set before the harvest was ready. Let's move to the next plot!");
  }

  void generateQuestion() {
    final rand = Random();
    int mode = (currentQuestion <= 2) ? rand.nextInt(2) : rand.nextInt(2) + 2;

    switch (mode) {
      case 0:
        int e = rand.nextInt(2) + 2;
        int d = e * (rand.nextInt(3) + 1);
        int c = rand.nextInt(3) + 2;
        int a = rand.nextInt(4) + 1;
        int b = rand.nextInt(3) + 1;
        correctAnswer = ((a + b) * c) - (d ~/ e);
        equationText = "( $a + $b ) × $c - ( $d ÷ $e )";
        break;
      case 1:
        int e = 2;
        int diff = rand.nextInt(3) + 2;
        int b = e * (rand.nextInt(2) + 1);
        int d = rand.nextInt(3) + 1;
        int c = d + diff;
        int a = rand.nextInt(5) + 1;
        correctAnswer = a + (b * (c - d)) ~/ e;
        equationText = "$a + [ $b × ( $c - $d ) ] ÷ $e";
        break;
      case 2:
        int e = 3;
        int inner = e * (rand.nextInt(3) + 2);
        int d = rand.nextInt(3) + 2;
        int product = inner + d;
        int c = (product % 2 == 0) ? 2 : 4;
        int sum = product ~/ c;
        int a = rand.nextInt(sum - 1) + 1;
        int b = sum - a;
        correctAnswer = (((a + b) * c) - d) ~/ e;
        equationText = "{ [ ( $a + $b ) × $c ] - $d } ÷ $e";
        break;
      default:
        int e = 2;
        int a = rand.nextInt(3) + 2;
        int b = rand.nextInt(3) + 2;
        int c = rand.nextInt(3) + 2;
        int d = rand.nextInt(3) + 2;
        correctAnswer = ((a * b) + (c * d)) ~/ e;
        equationText = "[ ( $a × $b ) + ( $c × $d ) ] ÷ $e";
    }

    if (correctAnswer > 15 || correctAnswer < 1) {
      generateQuestion();
      return;
    }

    multiplicand = 15;
    setState(() {
      harvestedIndices.clear();
      // Only start timer if loading is finished
      if (!_isLoading) _startHarvestTimer();
    });
  }

  void toggleHarvest(int index) {
    if (index >= multiplicand || _timerValue <= 0) return;
    setState(() {
      if (harvestedIndices.contains(index)) {
        harvestedIndices.remove(index);
      } else {
        harvestedIndices.add(index);
      }
    });
  }

  void submitHarvest() async {
    _countdownTimer?.cancel();
    bool isCorrect = harvestedIndices.length == correctAnswer;
    int timeSpent = 30 - _secondsRemaining;

    if (isCorrect) {
      int earnedXP = 10;
      if (timeSpent <= 5) {earnedXP += 10;}
      else if (timeSpent <= 10) {earnedXP += 5;}

      try {
        final client = Supabase.instance.client;
        await client.rpc('increment_xp', params: {'amount': earnedXP});
        await SupaService.saveGameSession(gameName: 'Fraction Fields', score: earnedXP, timeSpentSeconds: timeSpent);
      } catch (e) {
        debugPrint("XP Error: $e");
      }
      _showSuccessDialog(earnedXP);
    } else {
      _showFailureDialog("NOT QUITE!", "That harvest wasn't exactly what the farmer needed. Moving to the next plot!");
    }
  }

  void _moveToNext() {
    if (currentQuestion < totalQuestions) {
      setState(() => currentQuestion++);
      generateQuestion();
    } else {
      _showFinalResults();
    }
  }

  // --- IMPROVED DIALOGS ---

  void _showSuccessDialog(int xp) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: deepNavy,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: softBlue, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 60),
              const SizedBox(height: 15),
              Text("PERFECT HARVEST", style: GoogleFonts.lexend(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
              const SizedBox(height: 10),
              Text("+$xp XP EARNED", style: GoogleFonts.lexend(color: softBlue, fontSize: 18, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
              const SizedBox(height: 25),
              _dialogButton("CONTINUE", softBlue, _moveToNext),
            ],
          ),
        ),
      ),
    );
  }

  void _showFailureDialog(String title, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: deepNavy,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_twilight, color: Colors.orangeAccent, size: 60),
              const SizedBox(height: 15),
              Text(title, style: GoogleFonts.lexend(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.lexend(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.normal, decoration: TextDecoration.none)),
              const SizedBox(height: 25),
              _dialogButton("NEXT QUEST", Colors.orangeAccent, _moveToNext),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton(String label, Color color, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: () {
          Navigator.pop(context);
          action();
        },
        child: Text(label, style: GoogleFonts.lexend(color: deepNavy, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- ADDED LOADER LOGIC ---
    if (_isLoading) {
      return GameLoader(onComplete: () {
        setState(() {
          _isLoading = false;
          _startHarvestTimer(); // Start timer after loading
        });
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset('assets/field_night.png', fit: BoxFit.cover)),
                Positioned.fill(
                  child: Opacity(
                    opacity: _timerValue > 0.5 ? (1.0 - _timerValue) * 2 : (_timerValue * 2),
                    child: Image.asset('assets/field_dusk.png', fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: (_timerValue * 2 - 1.0).clamp(0.0, 1.0),
                    child: Image.asset('assets/field_day.png', fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 60, left: 20, right: 20,
            child: Row(
              children: [
                _buildSlimButton("EXIT", Icons.close, () => Navigator.pop(context)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _timerValue,
                          minHeight: 30,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _timerValue > 0.3 ? const Color(0xFFFFC741) : Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildSlimButton("RESET", Icons.refresh, () => setState(() => harvestedIndices.clear())),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 380,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 20, 40, 50),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 3.0,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: 15,
                    itemBuilder: (context, index) {
                      bool isAvailable = index < multiplicand;
                      bool isHarvested = harvestedIndices.contains(index);
                      return GestureDetector(
                        onTap: () => toggleHarvest(index),
                        child: isAvailable ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isHarvested ? const Icon(Icons.shopping_basket_rounded, color: Colors.greenAccent, size: 35)
                              : Image.asset('assets/crop.png', fit: BoxFit.contain),
                        ) : const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
              ),
              _buildBottomQuestCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlimButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [Icon(icon, color: Colors.white, size: 14), const SizedBox(width: 6), Text(label, style: GoogleFonts.lexend(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))]),
      ),
    );
  }

  Widget _buildBottomQuestCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: deepNavy.withOpacity(0.96), borderRadius: const BorderRadius.vertical(top: Radius.circular(45))),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("QUESTION $currentQuestion/5", style: GoogleFonts.lexend(color: softBlue, fontWeight: FontWeight.w900)),
                Text("HARVEST: ${harvestedIndices.length}", style: GoogleFonts.lexend(color: Colors.amber, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 25),
            Text(equationText, textAlign: TextAlign.center, style: GoogleFonts.lexend(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity, height: 45,
              child: ElevatedButton(
                onPressed: submitHarvest,
                style: ElevatedButton.styleFrom(backgroundColor: softBlue, foregroundColor: deepNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text("SUBMIT HARVEST", style: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showFinalResults() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            backgroundColor: deepNavy,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 90),
                const SizedBox(height: 25),
                Text("QUEST COMPLETE!", style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26)),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: softBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).maybePop();
                    },
                    child: Text("FINISH", style: GoogleFonts.lexend(
                        color: deepNavy, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// --- ADDED LOADER COMPONENT ---

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
              'assets/FRACTION FIELD LOAD.png', // Ensure this image exists
              height: 350,
              width: 350,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              "PREPARING THE FIELDS",
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