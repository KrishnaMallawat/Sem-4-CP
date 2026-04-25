import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

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

  // 7. Update Username (Legacy, maybe not used)
  static Future<void> updateUsername(String newUsername) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').update({
        'username': newUsername, 
      }).eq('id', user.id);
    }
  }

  // 8. Generate Unique User Tag
  static Future<String> generateUniqueTag() async {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    
    while (true) {
      String tag = String.fromCharCodes(Iterable.generate(5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      
      final existing = await _supabase.from('profiles').select('id').eq('user_tag', tag).maybeSingle();
      if (existing == null) {
        return tag; // Tag is unique!
      }
    }
  }

  // 9. Fetch Schools
  static Future<List<String>> getSchools() async {
    final res = await _supabase.from('schools').select('school_name').order('school_name');
    return (res as List).map((row) => row['school_name'] as String).toList();
  }

  // 10. Update Privacy Settings
  static Future<void> updatePrivacySettings({required String visibility, required String userTag}) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').update({
        'leaderboard_visibility': visibility,
        'user_tag': userTag,
      }).eq('id', user.id);
    }
  }

  // 11. Send Friend Request (by ID)
  static Future<void> sendFriendRequestById(String targetId) async {
    final myId = _supabase.auth.currentUser!.id;
    if (myId == targetId) throw Exception("You cannot add yourself.");
    
    // Check if already friends or pending
    final existing = await _supabase.from('friendships').select().or('and(requester_id.eq.$myId,addressee_id.eq.$targetId),and(requester_id.eq.$targetId,addressee_id.eq.$myId)').maybeSingle();
    if (existing != null) throw Exception("Friendship or request already exists.");

    await _supabase.from('friendships').insert({
      'requester_id': myId,
      'addressee_id': targetId,
    });
  }

  // 12. Send Friend Request (by Tag)
  static Future<void> sendFriendRequestByTag(String tag) async {
    final res = await _supabase.from('profiles').select('id').eq('user_tag', tag).maybeSingle();
    if (res == null) throw Exception("User tag not found.");
    await sendFriendRequestById(res['id'] as String);
  }

  // 13. Accept Friend Request
  static Future<void> acceptFriendRequest(String friendshipId) async {
    await _supabase.from('friendships').update({'status': 'accepted'}).eq('id', friendshipId);
  }

  // 14. Reject/Remove Friend
  static Future<void> removeOrRejectFriend(String friendshipId) async {
    await _supabase.from('friendships').delete().eq('id', friendshipId);
  }

  // 15. Get friendship record between current user and a target user
  // Returns null if no relationship, otherwise the full friendship row.
  static Future<Map<String, dynamic>?> getFriendshipWith(String targetId) async {
    final myId = _supabase.auth.currentUser!.id;
    return await _supabase
        .from('friendships')
        .select()
        .or('and(requester_id.eq.$myId,addressee_id.eq.$targetId),and(requester_id.eq.$targetId,addressee_id.eq.$myId)')
        .maybeSingle();
  }

  // 15. Stream Friendships
  static Stream<List<Map<String, dynamic>>> getFriendshipsStream() {
    return _supabase.from('friendships').stream(primaryKey: ['id']);
  }

  // 16. Save Game Session
  static Future<void> saveGameSession({
    required String gameName,
    required int score,
    required int timeSpentSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('game_sessions').insert({
        'user_id': user.id,
        'game_name': gameName,
        'score': score,
        'time_spent_seconds': timeSpentSeconds,
      });
    }
  }
}


