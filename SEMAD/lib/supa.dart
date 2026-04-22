import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupaService {
  static final _supabase = Supabase.instance.client;

  // Inside SupaService class in supa.dart
  static Future<String> uploadAvatar(File file, String userId) async {
    final fileExt = file.path.split('.').last;
    final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    // Upload to 'avatars' bucket
    await Supabase.instance.client.storage.from('avatars').upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    // Return the public URL
    return Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
  }

  // 1. Get Current User
  static User? get currentUser => _supabase.auth.currentUser;

  // 2. Auth State Changes (Listen if user logs in/out)
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 3. Sign Up
  static Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // 4. Update Profile (Grade/School)
  // Your SQL trigger already created the row, we just fill the details
  static Future<void> updateProfile({required String grade, required String school}) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').update({
        'grade': grade,
        'school': school,
      }).eq('id', user.id);
    }
  }

  // 5. Login
  static Future<AuthResponse> login(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 6. Logout
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // 7. Update Username
  static Future<void> updateUsername(String newUsername) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').update({
        'display_name': newUsername, // Ensure your SQL column is named display_name
      }).eq('id', user.id);
    }
  }
}
