import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mathquest/main.dart';
import 'package:mathquest/supa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathquest/ui_widgets.dart';

class MathQuestLogin extends StatefulWidget {
  const MathQuestLogin({super.key});

  @override
  State<MathQuestLogin> createState() => _MathQuestLoginState();
}

class _MathQuestLoginState extends State<MathQuestLogin> {
  bool _isPasswordVisible = false;
  bool _isSignUp = false; // Toggle state
  bool _isLoading = false;

  // CONTROLLERS
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _usernameController = TextEditingController();
  List<String> _schoolOptions = [];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final res = await Supabase.instance.client.from('schools').select('school_name').order('school_name');
      setState(() {
        _schoolOptions = (res as List).map((r) => r['school_name'].toString()).toList();
      });
    } catch(e) {
      debugPrint("Error loading schools: $e");
    }
  }

  final Color vibrantBlue = const Color(0xFF2196F3);
  final Color deepNavy = const Color(0xFF000C2D);
  final Color petalPink = const Color(0xFFFF80AB);

  // --- AUTH LOGIC ---
  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Please enter a valid email.");
      return;
    }
    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        if (_usernameController.text.trim().isEmpty || _gradeController.text.trim().isEmpty || _schoolController.text.trim().isEmpty) {
          _showSnackBar("Please fill in your Username, Grade and School.");
          setState(() => _isLoading = false);
          return;
        }

        // 1. SIGN UP
        final AuthResponse res = await SupaService.signUp(
          email,
          password,
        );

        // 2. GENERATE TAG
        final userTag = await SupaService.generateUniqueTag();

        // 3. UPDATE PROFILE
        // We pass the data to fill the row created by your SQL trigger
        await Supabase.instance.client.from('profiles').update({
          'username': _usernameController.text.trim(),
          'grade': _gradeController.text.trim(),
          'school': _schoolController.text.trim(),
          'user_tag': userTag,
        }).eq('id', res.user!.id);

        // Try inserting into schools table just in case it's new
        final schoolName = _schoolController.text.trim();
        if (schoolName.isNotEmpty) {
          try {
            await Supabase.instance.client.from('schools').insert({'school_name': schoolName});
          } catch(_) {} 
        }

        // 4. REDIRECT TO HOME
        if (res.user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MathQuestControlCenter()),
          );
        }
      } else {
        // 3. LOGIN
        await SupaService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MathQuestControlCenter()),
          );
        }
      }
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              petalPink.withOpacity(0.3),
              const Color(0xFF5D3DF8).withOpacity(0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.25, 0.5],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(painter: MagicGridPainter()),
              ),
            ),
            _buildBackgroundSymbol("?", top: -20, left: -30),
            _buildBackgroundSymbol("+", bottom: -50, right: -20),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calculate_rounded, color: Colors.white, size: 80),
                      const SizedBox(height: 20),

                      Text(
                        _isSignUp ? "JOIN THE QUEST" : "MATH QUEST",
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isSignUp
                            ? "Create your adventurer profile!"
                            : "Welcome back!\nWe're always here, waiting for you!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 35),

                      _buildPillInput(
                        hint: "email@example.com",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 15),
                      _buildPillInput(
                        hint: "Password",
                        icon: Icons.lock_outline,
                        isPass: true,
                        controller: _passwordController,
                      ),

                      // ADDITIONAL SIGNUP FIELDS
                      if (_isSignUp) ...[
                        const SizedBox(height: 15),
                        _buildPillInput(
                          hint: "Username",
                          icon: Icons.person_outline,
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 15),
                        _buildPillInput(
                          hint: "Grade (e.g. 7th)",
                          icon: Icons.school_outlined,
                          controller: _gradeController,
                        ),
                        const SizedBox(height: 15),
                        _buildSchoolAutocomplete(),
                      ],

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isSignUp ? "Already have an account? " : "Don't have an account? ",
                              style: GoogleFonts.lexend(color: Colors.white54, fontSize: 12)),
                          GestureDetector(
                            onTap: () => setState(() => _isSignUp = !_isSignUp),
                            child: Text(_isSignUp ? " Login" : " Sign Up",
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  fontSize: 12,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),

                      _isLoading
                          ? const CircularProgressIndicator(color: Color(0xFFFFC741))
                          : SizedBox(
                        width: 160,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC741),
                            foregroundColor: deepNavy,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isSignUp ? "Sign Up" : "Login",
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE PILL INPUT WITH CONTROLLER ---
  Widget _buildPillInput({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPass = false
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? !_isPasswordVisible : false,
        style: GoogleFonts.lexend(color: deepNavy, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: isPass
              ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade400,
              size: 18,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
          hintText: hint,
          hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  // Helper widgets (_buildBackgroundSymbol, _buildSocialBtn, etc. stay the same)
  Widget _buildBackgroundSymbol(String char, {double? top, double? left, double? bottom, double? right}) {
    return Positioned(
      top: top, left: left, bottom: bottom, right: right,
      child: Opacity(
        opacity: 0.05,
        child: Text(char, style: GoogleFonts.lexend(fontSize: 280, color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }
  Widget _buildSchoolAutocomplete() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
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
          if (controller.text.isEmpty && _schoolController.text.isNotEmpty) {
            controller.text = _schoolController.text;
          }
          controller.addListener(() {
            _schoolController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.lexend(color: deepNavy, fontSize: 14),
            decoration: InputDecoration(
              hintText: "School Name",
              hintStyle: GoogleFonts.lexend(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.business_outlined, color: Colors.grey.shade400, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.white,
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
                      title: Text(option, style: GoogleFonts.lexend(color: deepNavy, fontSize: 13)),
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
}
