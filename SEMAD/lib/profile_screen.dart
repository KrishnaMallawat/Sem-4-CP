import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:mathquest/ui_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  bool _isUploading = false;
  List<String> _schoolOptions = [];
  String _visibility = 'global';
  final _userTagController = TextEditingController();

  // Controllers
  final _nameController = TextEditingController(); // Added for Username
  final _schoolController = TextEditingController();
  final _gradeController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _isInitialDataLoaded = false;
  
  // Settings
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  // Domain Mapping for Radar Chart
  Map<String, double> _domainScores = {
    'Arithmetic': 0,
    'Fractions': 0,
    'Geometry': 0,
    'Logic': 0,
    'Speed': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Increased to 5 for Settings
    _loadSchools();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _soundEnabled = SettingsService.soundEnabled;
      _hapticsEnabled = SettingsService.hapticsEnabled;
    });
  }

  Future<void> _loadSchools() async {
    try {
      final res = await _supabase.from('schools').select('school_name').order('school_name');
      setState(() {
        _schoolOptions = (res as List).map((r) => r['school_name'].toString()).toList();
      });
    } catch(e) {
      debugPrint("Error loading schools: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _userTagController.dispose();
    super.dispose();
  }

  TextStyle lexendStyle({double size = 14, Color color = Colors.white, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.lexend(fontSize: size, color: color, fontWeight: weight);
  }

  // --- LOGIC: PICK & UPLOAD IMAGE ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '$userId.$fileExt';

      await _supabase.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = _supabase.storage.from('avatars').getPublicUrl(fileName);
      await _supabase.from('profiles').update({'avatar_url': url}).eq('id', userId);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Photo Updated!", style: lexendStyle())));
    } catch (e) {
      _showError("Upload failed: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- LOGIC: SAVE ALL INFO (NAME, SCHOOL, GRADE) ---
  Future<void> _saveGeneralInfo() async {
    final username = _nameController.text.trim();
    
    // VALIDATION
    if (username.isEmpty || username.length < 3 || username.length > 15) {
      _showError("Username must be 3-15 characters.");
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      _showError("Username can only contain letters, numbers, and underscores.");
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final schoolName = _schoolController.text.trim();
      if (schoolName.isNotEmpty) {
        try {
          await _supabase.from('schools').insert({'school_name': schoolName});
        } catch(_) {} // Ignore if already exists
      }

      await _supabase.from('profiles').update({
        'username': username,
        'school': schoolName,
        'grade': _gradeController.text.trim(),
        'leaderboard_visibility': _visibility,
        'user_tag': _userTagController.text.trim(),
      }).eq('id', _supabase.auth.currentUser!.id);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile Updated!", style: lexendStyle())));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: SAVE PRIVACY INFO ---
  Future<void> _savePrivacyInfo() async {
    final tag = _userTagController.text.trim();
    if (tag.isEmpty) {
      _showError("User Tag cannot be empty.");
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(tag)) {
      _showError("User Tag can only contain letters, numbers, and underscores.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('profiles').update({
        'leaderboard_visibility': _visibility,
        'user_tag': tag,
      }).eq('id', _supabase.auth.currentUser!.id);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Privacy Settings Saved!", style: lexendStyle())));
    } catch (e) {
      if (e.toString().contains('unique constraint')) {
        _showError("User Tag is already taken by someone else!");
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: UPDATE PASSWORD ---
  Future<void> _updatePassword() async {
    if (_passController.text != _confirmPassController.text) {
      _showError("Passwords do not match!");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: _passController.text.trim()));
      _passController.clear();
      _confirmPassController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password Changed!", style: lexendStyle())));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: lexendStyle(color: Colors.redAccent))));
  }

  @override
  Widget build(BuildContext context) {
    const Color deepNavy = Color(0xFF000C2D);
    const Color themeYellow = Color(0xFFFFC741);
    const Color petalPink = Color(0xFFFF80AB);

    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        title: Text("PLAYER SETTINGS", style: lexendStyle(size: 18, weight: FontWeight.w500, color: Colors.white70)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: themeYellow,
          labelStyle: lexendStyle(weight: FontWeight.bold, size: 10),
          tabs: const [
            Tab(text: "PROFILE", icon: Icon(Icons.badge_outlined)),
            Tab(text: "STATS", icon: Icon(Icons.bar_chart_outlined)),
            Tab(text: "PRIVACY", icon: Icon(Icons.visibility_outlined)),
            Tab(text: "SECURITY", icon: Icon(Icons.lock_outline)),
            Tab(text: "SETTINGS", icon: Icon(Icons.settings_outlined)),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Stack(
          children: [
            Positioned.fill(child: Opacity(opacity: 0.1, child: CustomPaint(painter: MagicGridPainter()))),
            StreamBuilder(
              stream: _supabase.from('profiles').stream(primaryKey: ['id']).eq('id', _supabase.auth.currentUser!.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: themeYellow));

                final data = snapshot.data!.first;
                
                if (!_isInitialDataLoaded) {
                  _nameController.text = data['username'] ?? "";
                  _schoolController.text = data['school'] ?? "";
                  _gradeController.text = data['grade'] ?? "";
                  _userTagController.text = data['user_tag'] ?? "";
                  if (data['leaderboard_visibility'] != null) {
                    _visibility = data['leaderboard_visibility'];
                  }
                  _isInitialDataLoaded = true;
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(data, themeYellow, deepNavy),
                    _buildStatsTab(themeYellow, deepNavy),
                    _buildPrivacyTab(themeYellow, deepNavy),
                    _buildSecurityTab(themeYellow, deepNavy),
                    _buildSettingsTab(themeYellow, deepNavy),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(Map data, Color yellow, Color navy) {
    bool isComplete = data['school'] != null && data['grade'] != null && data['username'] != null;
    String? avatarUrl = data['avatar_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          // --- PHOTO SECTION ---
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: yellow.withOpacity(0.1),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? Icon(Icons.person_add_rounded, size: 40, color: yellow) : null,
                ),
                if (_isUploading) const SizedBox(width: 110, height: 110, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: yellow, child: Icon(Icons.camera_alt, size: 18, color: navy))),
              ],
            ),
          ),
          const SizedBox(height: 30),

          if (!isComplete) ...[
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: yellow)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text("Complete your profile to secure your rank!", style: lexendStyle(size: 12, color: yellow))),
              ]),
            ),
          ],

          // --- ALL FIELDS IN SAME STYLE ---
          _buildField("USERNAME", _nameController),
          _buildSchoolAutocomplete(),
          _buildField("GRADE (E.G. 8TH)", _gradeController),

          const SizedBox(height: 30),
          _buildActionBtn("SAVE PROFILE INFO", _saveGeneralInfo, yellow, navy),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab(Color yellow, Color navy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("LEADERBOARD VISIBILITY", style: lexendStyle(size: 14, color: Colors.white70, weight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                _buildSegment('global', 'GLOBAL', Icons.public),
                _buildSegment('school', 'SCHOOL', Icons.school),
                _buildSegment('hidden', 'HIDDEN', Icons.visibility_off),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text("FRIEND TAG", style: lexendStyle(size: 14, color: Colors.white70, weight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Share this tag with friends so they can add you to their leaderboard.", style: lexendStyle(size: 11, color: Colors.white54)),
          const SizedBox(height: 15),
          _buildField("USER TAG", _userTagController),
          const SizedBox(height: 40),
          _buildActionBtn("SAVE SETTINGS", _savePrivacyInfo, yellow, navy),
        ],
      ),
    );
  }

  Widget _buildSegment(String value, String label, IconData icon) {
    bool isSelected = _visibility == value;
    return GestureDetector(
      onTap: () => setState(() => _visibility = value),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC741) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF000C2D) : Colors.white54),
            const SizedBox(width: 8),
            Text(label, style: lexendStyle(size: 11, color: isSelected ? const Color(0xFF000C2D) : Colors.white54, weight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab(Color yellow, Color navy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Text("CHANGE PASSWORD", style: lexendStyle(size: 16, weight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildField("NEW PASSWORD", _passController, isPass: true),
          _buildField("CONFIRM NEW PASSWORD", _confirmPassController, isPass: true),
          const SizedBox(height: 30),
          _buildActionBtn("UPDATE PASSWORD", _updatePassword, yellow, navy),
        ],
      ),
    );
  }

  Widget _buildSchoolAutocomplete() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return _schoolOptions.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          _schoolController.text = selection;
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          // Sync controllers
          if (controller.text.isEmpty && _schoolController.text.isNotEmpty) {
            controller.text = _schoolController.text;
          }
          controller.addListener(() {
            _schoolController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: lexendStyle(),
            decoration: InputDecoration(
              labelText: "SCHOOL NAME",
              labelStyle: lexendStyle(size: 10, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: const Color(0xFF000C2D),
              elevation: 4.0,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return ListTile(
                      title: Text(option, style: lexendStyle(size: 12)),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: lexendStyle(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: lexendStyle(size: 10, color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onPress, Color yellow, Color navy) {
    return _isLoading
        ? const CircularProgressIndicator(color: Colors.white)
        : ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: yellow,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPress,
      child: Text(label, style: lexendStyle(color: navy, weight: FontWeight.bold)),
    );
  }

  Widget _buildStatsTab(Color yellow, Color navy) {
    return FutureBuilder(
      future: Future.wait([
        _supabase.from('user_game_stats').select().eq('user_id', _supabase.auth.currentUser!.id),
        _supabase.from('game_sessions').select().eq('user_id', _supabase.auth.currentUser!.id).order('played_at', ascending: false).limit(5),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: yellow));
        }
        
        final stats = snapshot.data?[0] as List? ?? [];
        final history = snapshot.data?[1] as List? ?? [];

        // Calculate domain scores for radar chart
        for (var stat in stats) {
          String game = stat['game_name'];
          double score = (stat['max_score'] ?? 0).toDouble();
          if (game == 'Bazaar Bill') _domainScores['Arithmetic'] = score;
          if (game == 'Fraction Fields') _domainScores['Fractions'] = score;
          if (game == 'Shape Surge') _domainScores['Geometry'] = score;
          if (game == 'Formula Flash') _domainScores['Logic'] = score;
          if (game == 'Quick Tick') _domainScores['Speed'] = score;
        }

        // Find weakest domain
        String weakest = 'Arithmetic';
        double minVal = 999;
        _domainScores.forEach((k, v) {
          if (v < minVal) {
            minVal = v;
            weakest = k;
          }
        });

        Map<String, String> recommendations = {
          'Arithmetic': 'Play Bazaar Bill to master your addition!',
          'Fractions': 'Try Fraction Fields to boost your scaling skills.',
          'Geometry': 'Slice through shapes in Shape Surge!',
          'Logic': 'Match patterns in Formula Flash.',
          'Speed': 'Race against time in Quick Tick.',
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SKILL ANALYSIS", style: lexendStyle(size: 14, color: Colors.white70, weight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Radar Chart Card
              Container(
                height: 250,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: CustomPaint(
                  painter: RadarChartPainter(_domainScores, yellow),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Recommendation Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [yellow.withOpacity(0.2), Colors.transparent]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: yellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: yellow),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("GROWTH INSIGHT", style: lexendStyle(size: 10, color: yellow, weight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(recommendations[weakest] ?? "Keep playing to see insights!", style: lexendStyle(size: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 35),
              Text("RECENT MISSIONS", style: lexendStyle(size: 14, color: Colors.white70, weight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              ...history.map((session) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session['game_name'], style: lexendStyle(weight: FontWeight.bold)),
                          Text(
                            DateTime.parse(session['played_at']).toLocal().toString().split(' ')[0],
                            style: lexendStyle(size: 10, color: Colors.white38),
                          ),
                        ],
                      ),
                      Text("+${session['score']} XP", style: lexendStyle(color: yellow, weight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
              
              if (history.isEmpty)
                Center(child: Text("No missions recorded yet.", style: lexendStyle(color: Colors.white24))),
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(Color yellow, Color navy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("GAME PREFERENCES", style: lexendStyle(size: 14, color: Colors.white70, weight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildToggleSetting("SOUND EFFECTS", "Enable immersive game sounds", _soundEnabled, (v) async {
            setState(() => _soundEnabled = v);
            await SettingsService.setSound(v);
          }, yellow),
          _buildToggleSetting("HAPTIC FEEDBACK", "Tactile vibrations during play", _hapticsEnabled, (v) async {
            setState(() => _hapticsEnabled = v);
            await SettingsService.setHaptics(v);
          }, yellow),
          
          const SizedBox(height: 40),
          Text("ABOUT MATHQUEST", style: lexendStyle(size: 14, color: Colors.white70, weight: FontWeight.bold)),
          const SizedBox(height: 15),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Version", style: lexendStyle()),
            trailing: Text("1.0.0", style: lexendStyle(color: Colors.white38)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Clear Game Cache", style: lexendStyle()),
            trailing: Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting(String title, String subtitle, bool value, Function(bool) onChanged, Color yellow) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: lexendStyle(weight: FontWeight.bold)),
                Text(subtitle, style: lexendStyle(size: 11, color: Colors.white38)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: yellow,
            activeTrackColor: yellow.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lexend(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.lexend(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> scores;
  final Color color;

  RadarChartPainter(this.scores, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.7;
    final domains = scores.keys.toList();
    final angleStep = (2 * math.pi) / domains.length;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw background spokes and circles
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), linePaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < domains.length; i++) {
      final angle = i * angleStep - (math.pi / 2);
      
      // Spoke line
      final spokeEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, spokeEnd, linePaint);

      // Label
      textPainter.text = TextSpan(
        text: domains[i].toUpperCase(),
        style: GoogleFonts.lexend(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      final labelOffset = Offset(
        center.dx + (radius + 20) * math.cos(angle) - (textPainter.width / 2),
        center.dy + (radius + 20) * math.sin(angle) - (textPainter.height / 2),
      );
      textPainter.paint(canvas, labelOffset);

      // Score point
      double score = (scores[domains[i]] ?? 0).clamp(0, 500); // Scale: max 500 XP per domain for chart
      double normalized = (score / 500).clamp(0.1, 1.0); 
      points.add(Offset(
        center.dx + radius * normalized * math.cos(angle),
        center.dy + radius * normalized * math.sin(angle),
      ));
    }

    // Draw score polygon
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
    
    // Draw points
    for (var p in points) {
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(RadarChartPainter old) => true;
}
