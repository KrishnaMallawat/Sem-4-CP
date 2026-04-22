import 'package:flutter/material.dart';
import 'package:mathquest/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mathquest/games/bazaar_bill.dart';
import 'package:mathquest/games/formula_flash.dart';
import 'package:mathquest/games/fraction_fields.dart';
import 'package:mathquest/games/shape_surge.dart';
import 'package:mathquest/games/quick_tick.dart';
import 'package:mathquest/splash_screen.dart';
import 'package:mathquest/supa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathquest/profile_screen.dart';
import 'package:mathquest/ui_widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MathQuestApp());
}

final supabase = Supabase.instance.client;

class MathQuestApp extends StatelessWidget {
  const MathQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MATH QUEST',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF80D8FF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
      ),
      routes: {
        '/': (context) => const MathQuestLoading(),
        '/login': (context) => const MathQuestLogin(),
        '/home': (context) => const GanitControlCenter(),
      },
      initialRoute: '/',
    );
  }
}

class GanitControlCenter extends StatelessWidget {
  const GanitControlCenter({super.key});

  final List<Map<String, String>> games = const [
    {"title": "BAZAAR BILL", "img": "assets/1.png"},
    {"title": "FORMULA FLASH", "img": "assets/6.png"},
    {"title": "FRACTION FIELD", "img": "assets/8.png"},
    {"title": "QUICK TICK", "img": "assets/7.png"},
    {"title": "SHAPE SURGE", "img": "assets/2.png"},
    {"title": "PAIR UP", "img": "assets/5.png"},
    {"title": "GRID GUARDIAN", "img": "assets/3.png"},
    {"title": "TARGET BLITZZ", "img": "assets/4.png"},
  ];

  @override
  Widget build(BuildContext context) {
    const Color deepNavy = Color(0xFF000C2D);
    const Color themeYellow = Color(0xFFFFC741);

    return Scaffold(
      backgroundColor: deepNavy,
      // THIS APPBAR KEEPS THE MENU AND XP IN ONE ROW
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,

        // 1. THE MENU (LEFT SIDE)
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 25),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),

        // 2. THE XP BOX (RIGHT SIDE)
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Color(0xFFFFC741), size: 24),
            onPressed: () => _showLeaderboard(context), // Opens a small tab
          ),

          // 2. ACHIEVEMENTS ICON
          IconButton(
            icon: const Icon(Icons.verified_outlined, color: Colors.cyanAccent, size: 24),
            onPressed: () => _showAchievements(context), // Opens a small tab
          ),

          StreamBuilder(
            stream: supabase
                .from('profiles')
                .stream(primaryKey: ['id']) // Tells Supabase to watch this row
                .eq('id', supabase.auth.currentUser!.id),
            builder: (context, snapshot) {
              int xpValue = 0;
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                xpValue = snapshot.data!.first['xp'] ?? 0;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 20.0, top: 0.0, left: 10.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001242),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: themeYellow, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "$xpValue",
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor: deepNavy,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            // Drawer Header with Image
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.transparent, width: 0)),
                image: DecorationImage(
                  image: AssetImage("assets/drawer.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: const SizedBox(height: 160, width: double.infinity),
            ),
            const SizedBox(height: 10),
            _buildDrawerItem(Icons.person_outline, "Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }),
            _buildDrawerItem(Icons.info_outline, "Instructions", () {
              _showInstructions(context);
            }),
            const Spacer(),
            _buildDrawerItem(Icons.logout_rounded, "LOG OUT", () async {
              await SupaService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            }, color: Colors.redAccent),
            const SizedBox(height: 60),
          ],
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          LayoutBuilder(
            builder: (context, constraints) {
              double hPadding = constraints.maxWidth > 800 ? 80 : 30;

              return ScrollConfiguration(
                behavior: NoThumbScrollBehavior(),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 30,
                          childAspectRatio: 1.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => GameModuleCard(
                            title: games[index]["title"]!,
                            imagePath: games[index]["img"]!,
                          ),
                          childCount: games.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.lexend(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000C2D),
        title: Text("HOW TO PLAY", style: GoogleFonts.lexend(color: const Color(0xFFFFC741))),
        content: Text(
          "Select a module to start your training. Complete equations to earn XP and level up your adventurer!",
          style: GoogleFonts.lexend(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("GOT IT"),
          )
        ],
      ),
    );
  }
}

class GameModuleCard extends StatefulWidget {
  final String title;
  final String imagePath;

  const GameModuleCard({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  State<GameModuleCard> createState() => _GameModuleCardState();
}

class _GameModuleCardState extends State<GameModuleCard> {
  bool _isPressed = false;

  void _showSmallTabInstructions(BuildContext context) {
    // 1. Define instructions as a list to allow lines between them
    List<String> instructions = [];

    if (widget.title == "BAZAAR BILL") {
      instructions = [
        "🛒 Be the shopkeeper!",
        "Add the prices on the receipt.",
        "Enter the Total in the white box.",
        "Tap currency notes to give back the correct change!"
      ];
    } else if (widget.title == "FORMULA FLASH") {
      instructions = [
        "⚡ Solve equations fast!",
        "Watch the timer carefully.",
        "Beat your high score!"
      ];
    } else {
      instructions = ["Instructions coming soon!"];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF000C2D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TITLE
              Text(
                widget.title,
                style: GoogleFonts.lexend(
                  color: const Color(0xFFFFC741),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              // 2. INSTRUCTIONS WITH LINES BETWEEN EACH
              ...instructions.expand((text) => [
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(color: Colors.white, fontSize: 15),
                ),
                // Only add a line if it's NOT the last item
                if (text != instructions.last)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 0.5,
                    width: 300, // Short, thin line between steps
                    color: Colors.white10,
                  ),
              ]),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("GOT IT", style: GoogleFonts.lexend(color: const Color(0xFFFFC741))),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            switch (widget.title) {
              case "BAZAAR BILL":
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BazaarBillGame()));
                break;
              case "FORMULA FLASH":
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FormulaFlashGame()));
                break;
              case "FRACTION FIELD":
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FractionApp()));
                break;
              case "QUICK TICK":
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SamaySudhaarGame()));
                break;
              case "SHAPE SURGE":
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MathShapeNinjaGame()));
                break;
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${widget.title} coming soon!")),
                );
            }
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.zero,
                  color: Colors.transparent,
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomLeft,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // --- THE WHITE "i" CIRCLE (TOP RIGHT) ---
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _showSmallTabInstructions(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white, // White circle
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF000C2D), // Deep Navy icon
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



class NoThumbScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(context, child, details) => child;
}

void _showLeaderboard(BuildContext context) {
  const Color deepNavy = Color(0xFF000C2D);
  const Color themeYellow = Color(0xFFFFC741);
  const Color petalPink = Color(0xFFFF80AB);

  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        backgroundColor: deepNavy, // Solid base
        body: Stack(
          children: [
            // 1. THE LOGIN PAGE GRADIENT
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    petalPink.withOpacity(0.2),
                    const Color(0xFF5D3DF8).withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.5],
                ),
              ),
            ),

            // 2. THE GRID SYSTEM (Opacity 0.1 for subtle look)
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(painter: MagicGridPainter()),
              ),
            ),

            // 3. THE CONTENT
            SafeArea(
              child: Column(
                children: [
                  // --- CUSTOM APP BAR ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "GLOBAL RANKINGS",
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- THE RANKINGS LIST ---
                  Expanded(
                    child: StreamBuilder(
                      stream: supabase
                          .from('profiles')
                          .stream(primaryKey: ['id'])
                          .order('xp', ascending: false)
                          .limit(20),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: themeYellow));
                        }

                        final players = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Bottom padding for controls
                          physics: const BouncingScrollPhysics(),
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            bool isMe = player['id'] == supabase.auth.currentUser!.id;

                            Color rankColor = index == 0 ? themeYellow : (index == 1 ? Colors.white70 : (index == 2 ? Colors.orangeAccent : Colors.white24));

                            return Container(
                              // 1. Reduce the gap between rows
                              margin: const EdgeInsets.only(bottom: 15),

                              // 2. Slim down the internal spacing (Vertical from 16 to 10)
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                              decoration: BoxDecoration(
                                color: isMe ? petalPink.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isMe ? petalPink.withOpacity(1.0) : Colors.white.withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // RANK
                                  SizedBox(
                                    width: 35,
                                    child: Text("${index + 1}",
                                        style: GoogleFonts.lexend(color: rankColor, fontWeight: FontWeight.w900, fontSize: 22)),
                                  ),
                                  const SizedBox(width: 10),

                                  // AVATAR
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: player['avatar_url'] != null ? NetworkImage(player['avatar_url']) : null,
                                    child: player['avatar_url'] == null ? const Icon(Icons.person, size: 20, color: Colors.white24) : null,
                                  ),
                                  const SizedBox(width: 15),

                                  // NAME
                                  Expanded(
                                    child: Text(
                                        player['username'] ?? "ADVENTURER",
                                        style: GoogleFonts.lexend(
                                            color: isMe ? Colors.white : Colors.white70,
                                            fontWeight: isMe ? FontWeight.w700 : FontWeight.w400,
                                            fontSize: 16
                                        )
                                    ),
                                  ),

                                  // XP
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("${player['xp']}",
                                          style: GoogleFonts.lexend(color: themeYellow, fontWeight: FontWeight.w900, fontSize: 18)),
                                      Text("XP", style: GoogleFonts.lexend(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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

void _showAchievements(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF000C2D), // Deep Navy
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (context) {
      return StreamBuilder(
        stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', supabase.auth.currentUser!.id),
        builder: (context, snapshot) {
          int currentXP = 0;
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            currentXP = snapshot.data!.first['xp'] ?? 0;
          }

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "ADVENTURER BADGES",
                  style: GoogleFonts.lexend(
                    color: const Color(0xFFFFC741),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Divider(color: Colors.white10, thickness: 0.5),
                const SizedBox(height: 15),

                // Achievement List
                _badgeRow("NOVICE TRADER", "Reach 100 XP", currentXP >= 100, Icons.auto_awesome),
                _badgeRow("MATH WARRIOR", "Reach 500 XP", currentXP >= 500, Icons.shield_rounded),
                _badgeRow("NUMERICAL NINJA", "Reach 1000 XP", currentXP >= 1000, Icons.bolt_rounded),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("BACK TO QUEST", style: GoogleFonts.lexend(color: const Color(0xFFFFC741))),
                ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _badgeRow(String name, String goal, bool isUnlocked, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        // Badge Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUnlocked ? const Color(0xFFFFC741).withOpacity(0.1) : Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isUnlocked ? const Color(0xFFFFC741) : Colors.white24,
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        // Badge Name & Task
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.lexend(
                color: isUnlocked ? Colors.white : Colors.white24,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              goal,
              style: GoogleFonts.lexend(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        // Status Text
        if (isUnlocked)
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20)
        else
          const Icon(Icons.lock_outline, color: Colors.white10, size: 20),
      ],
    ),
  );
}