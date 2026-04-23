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

class GanitControlCenter extends StatefulWidget {
  const GanitControlCenter({super.key});

  @override
  State<GanitControlCenter> createState() => _GanitControlCenterState();
}

class _GanitControlCenterState extends State<GanitControlCenter> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeGridScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000C2D),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF000C2D),
        selectedItemColor: const Color(0xFFFFC741),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.gamepad_rounded), label: "PLAY"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: "RANKINGS"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "PROFILE"),
        ],
      ),
    );
  }
}

class HomeGridScreen extends StatelessWidget {
  const HomeGridScreen({super.key});

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

        // NO MENU DRAWER NOW, JUST A LOGO
        leading: const Icon(Icons.calculate_rounded, color: themeYellow, size: 28),

        // 2. THE XP BOX (RIGHT SIDE)
        actions: [
          // 1. LOGOUT
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            onPressed: () async {
              await SupaService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
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

      // NO DRAWER

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
              case "PAIR UP":
              case "GRID GUARDIAN":
              case "TARGET BLITZZ":
                // Handle visually via overlay, don't navigate
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    image: DecorationImage(
                      image: AssetImage(widget.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (widget.title == "PAIR UP" || widget.title == "GRID GUARDIAN" || widget.title == "TARGET BLITZZ")
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, color: Colors.white54, size: 30),
                          const SizedBox(height: 5),
                          Text(
                            "COMING SOON",
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
              ],
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

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color deepNavy = Color(0xFF000C2D);
    const Color themeYellow = Color(0xFFFFC741);
    const Color petalPink = Color(0xFFFF80AB);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: deepNavy,
        appBar: AppBar(
          backgroundColor: deepNavy,
          elevation: 0,
          title: Text(
            "RANKINGS",
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          bottom: TabBar(
            indicatorColor: themeYellow,
            labelColor: themeYellow,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: "GLOBAL"),
              Tab(text: "SCHOOL"),
              Tab(text: "FRIENDS"),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: MagicGridPainter()),
              ),
            ),
            TabBarView(
              children: [
                _buildLeaderboardTab(themeYellow, petalPink, filter: 'global'),
                _buildLeaderboardTab(themeYellow, petalPink, filter: 'school'),
                _buildFriendsTab(context, themeYellow, petalPink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildLeaderboardTab(Color themeYellow, Color petalPink, {required String filter}) {
  return StreamBuilder(
    stream: supabase.from('profiles').stream(primaryKey: ['id']).order('xp', ascending: false),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator(color: themeYellow));
      }

      final allPlayers = snapshot.data!;
      final currentUserId = supabase.auth.currentUser!.id;
      final currentUserProfile = allPlayers.firstWhere((p) => p['id'] == currentUserId, orElse: () => {});
      final mySchool = currentUserProfile['school'];

      List<Map<String, dynamic>> filteredPlayers = [];

      for (var p in allPlayers) {
        String visibility = p['leaderboard_visibility'] ?? 'global';
        bool isMe = p['id'] == currentUserId;

        if (filter == 'global') {
          if (visibility == 'school' && !isMe) continue; // Hide school-only from global unless me
          filteredPlayers.add(p);
        } else if (filter == 'school') {
          if (mySchool == null || mySchool.isEmpty) continue; 
          if (p['school'] != mySchool) continue; 
          filteredPlayers.add(p);
        }
      }

      // Re-sort just in case, limit to top 50
      filteredPlayers.sort((a, b) => (b['xp'] ?? 0).compareTo(a['xp'] ?? 0));
      if (filteredPlayers.length > 50) filteredPlayers = filteredPlayers.sublist(0, 50);

      if (filteredPlayers.isEmpty) {
        return Center(
          child: Text(
            filter == 'school' ? "Set your school to see rankings!" : "No players found.",
            style: GoogleFonts.lexend(color: Colors.white54),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        physics: const BouncingScrollPhysics(),
        itemCount: filteredPlayers.length,
        itemBuilder: (context, index) {
          final player = filteredPlayers[index];
          bool isMe = player['id'] == currentUserId;
          String visibility = player['leaderboard_visibility'] ?? 'global';
          
          String displayName = player['username'] ?? "ADVENTURER";
          if (!isMe && visibility == 'hidden') {
            displayName = "Anonymous Adventurer";
          }

          Color rankColor = index == 0 ? themeYellow : (index == 1 ? Colors.white70 : (index == 2 ? Colors.orangeAccent : Colors.white24));

          return GestureDetector(
            onTap: () => _showPlayerProfileBottomSheet(context, player, isMe),
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
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
                SizedBox(
                  width: 35,
                  child: Text("${index + 1}", style: GoogleFonts.lexend(color: rankColor, fontWeight: FontWeight.w900, fontSize: 22)),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white12,
                  backgroundImage: (player['avatar_url'] != null && visibility != 'hidden') ? NetworkImage(player['avatar_url']) : null,
                  child: (player['avatar_url'] == null || visibility == 'hidden') ? const Icon(Icons.person, size: 20, color: Colors.white24) : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    displayName,
                    style: GoogleFonts.lexend(
                      color: isMe ? Colors.white : Colors.white70,
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 16
                    )
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${player['xp'] ?? 0}", style: GoogleFonts.lexend(color: themeYellow, fontWeight: FontWeight.w900, fontSize: 18)),
                    Text("XP", style: GoogleFonts.lexend(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
           ),
          );
        },
      );
    },
  );
}

void _showPlayerProfileBottomSheet(BuildContext context, Map<String, dynamic> player, bool isMe) {
  final Color themeYellow = const Color(0xFFFFC741);
  final String? avatarUrl = player['avatar_url'];
  
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF000C2D),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white12,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white24) : null,
            ),
            const SizedBox(height: 15),
            Text(player['username'] ?? 'ADVENTURER', style: GoogleFonts.lexend(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            if (player['school'] != null && player['school'].toString().isNotEmpty) 
              Text(player['school'], style: GoogleFonts.lexend(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: themeYellow.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text("${player['xp'] ?? 0} XP", style: GoogleFonts.lexend(color: themeYellow, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            if (!isMe)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeYellow,
                  foregroundColor: const Color(0xFF000C2D),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.person_add_rounded),
                label: Text("SEND FRIEND REQUEST", style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  try {
                    await SupaService.sendFriendRequestById(player['id']);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request sent!")));
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
                  }
                },
              )
          ],
        ),
      );
    }
  );
}

Widget _buildFriendsTab(BuildContext context, Color themeYellow, Color petalPink) {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: SupaService.getFriendshipsStream(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: themeYellow));

      final friendships = snapshot.data!;
      final myId = supabase.auth.currentUser!.id;

      final pendingIncoming = friendships.where((f) => f['status'] == 'pending' && f['addressee_id'] == myId).toList();
      final accepted = friendships.where((f) => f['status'] == 'accepted').toList();

      final userIdsToFetch = <String>{};
      for (var f in pendingIncoming) userIdsToFetch.add(f['requester_id']);
      for (var f in accepted) {
        userIdsToFetch.add(f['requester_id'] == myId ? f['addressee_id'] : f['requester_id']);
      }

      return FutureBuilder(
        // Always execute future, but if list is empty, just return empty list to avoid Supabase error
        future: userIdsToFetch.isEmpty 
          ? Future.value([]) 
          : supabase.from('profiles').select().inFilter('id', userIdsToFetch.toList()),
        builder: (context, profileSnap) {
          if (!profileSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white24));

          final profiles = (profileSnap.data as List).cast<Map<String, dynamic>>();
          
          // Sort accepted friends by XP
          final acceptedProfiles = profiles.where((p) => accepted.any((f) => f['requester_id'] == p['id'] || f['addressee_id'] == p['id'])).toList();
          acceptedProfiles.sort((a, b) => (b['xp'] ?? 0).compareTo(a['xp'] ?? 0));

          return ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. ADD FRIEND BUTTON
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text("ADD FRIEND BY TAG", style: GoogleFonts.lexend()),
                onPressed: () => _showAddFriendDialog(context),
              ),
              const SizedBox(height: 30),

              // 2. PENDING REQUESTS
              if (pendingIncoming.isNotEmpty) ...[
                Text("PENDING REQUESTS", style: GoogleFonts.lexend(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...pendingIncoming.map((f) {
                  final p = profiles.firstWhere((profile) => profile['id'] == f['requester_id'], orElse: () => {});
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white12,
                          backgroundImage: p['avatar_url'] != null ? NetworkImage(p['avatar_url']) : null,
                          child: p['avatar_url'] == null ? const Icon(Icons.person, size: 18, color: Colors.white24) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(p['username'] ?? 'Unknown', style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                          onPressed: () => SupaService.acceptFriendRequest(f['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          onPressed: () => SupaService.removeOrRejectFriend(f['id']),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 30),
              ],

              // 3. ACCEPTED FRIENDS LEADERBOARD
              Text("YOUR SQUAD", style: GoogleFonts.lexend(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (acceptedProfiles.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text("No friends yet. Add someone!", style: GoogleFonts.lexend(color: Colors.white38)),
                )),
              ...acceptedProfiles.asMap().entries.map((entry) {
                int index = entry.key;
                var player = entry.value;
                Color rankColor = index == 0 ? themeYellow : (index == 1 ? Colors.white70 : (index == 2 ? Colors.orangeAccent : Colors.white24));
                
                return GestureDetector(
                  onTap: () => _showPlayerProfileBottomSheet(context, player, false),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text("${index + 1}", style: GoogleFonts.lexend(color: rankColor, fontWeight: FontWeight.bold, fontSize: 18))),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white12,
                          backgroundImage: player['avatar_url'] != null ? NetworkImage(player['avatar_url']) : null,
                          child: player['avatar_url'] == null ? const Icon(Icons.person, size: 16, color: Colors.white24) : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(child: Text(player['username'] ?? "ADVENTURER", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                        Text("${player['xp'] ?? 0} XP", style: GoogleFonts.lexend(color: themeYellow, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
    },
  );
}

void _showAddFriendDialog(BuildContext context) {
  final tagController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF000C2D),
        title: Text("ADD FRIEND", style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tagController,
          style: GoogleFonts.lexend(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter Friend's Tag (e.g. alex1234)",
            hintStyle: GoogleFonts.lexend(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.lexend(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC741)),
            onPressed: () async {
              try {
                await SupaService.sendFriendRequestByTag(tagController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request sent!")));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
              }
            },
            child: Text("SEND", style: GoogleFonts.lexend(color: const Color(0xFF000C2D), fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
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