import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/user_input.dart';
import 'models/match.dart';
import 'supabase_config.dart';

class SupabaseService {
  static Future<List<String>> uploadPhotos(List<Uint8List> photos) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final List<String> urls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < photos.length; i++) {
      final path = '${user.id}/${timestamp}_$i.jpg';

      await supabase.storage.from('avatars').uploadBinary(
            path,
            photos[i],
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final url = supabase.storage.from('avatars').getPublicUrl(path);
      urls.add(url);
    }

    return urls;
  }

  static Future<void> saveProfile(UserInput user, List<String> photoUrls) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception('Пользователь не авторизован');

    await supabase.from('profiles').upsert({
      'id': currentUser.id,
      'user_id': currentUser.id,
      'name': user.name,
      'age': user.age,
      'city': user.city,
      'gender': user.gender,
      'relationship_goal': user.relationshipGoal,
      'about': user.about,
      'expectation': user.expectation,
      'interests': user.interests,
      'traits': user.traits,
      'partner_traits': user.partnerTraits,
      'appearance': user.appearance,
      'photo_urls': photoUrls,
    });
  }

  static Future<UserInput?> loadOwnProfile() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('user_id', currentUser.id)
        .maybeSingle();

    if (data == null) return null;
    return _profileFromRow(data);
  }

  static Future<List<UserInput>> loadOtherProfiles({required bool includeBots}) async {
    final currentUser = supabase.auth.currentUser;

    var query = supabase.from('profiles').select();
    if (currentUser != null) {
      query = query.or('user_id.is.null,user_id.neq.${currentUser.id}');
    }
    if (!includeBots) {
      query = query.eq('is_bot', false);
    }

    final data = await query;

    return (data as List)
        .map((row) => _profileFromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> likeUser(String toProfileId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception('Пользователь не авторизован');

    await supabase.from('likes').upsert({
      'from_user_id': currentUser.id,
      'to_user_id': toProfileId,
    }, onConflict: 'from_user_id,to_user_id');

    final reverse = await supabase
        .from('likes')
        .select()
        .eq('from_user_id', toProfileId)
        .eq('to_user_id', currentUser.id)
        .maybeSingle();

    if (reverse == null) return false;

    final ids = [currentUser.id, toProfileId]..sort();
    await supabase.from('matches').upsert({
      'user_a': ids[0],
      'user_b': ids[1],
    }, onConflict: 'user_a,user_b');

    return true;
  }

  static Future<List<Match>> loadMatches() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return [];

    final data = await supabase
        .from('matches')
        .select()
        .or('user_a.eq.${currentUser.id},user_b.eq.${currentUser.id}');

    final List<Match> matches = [];
    for (final row in data as List) {
      final otherId =
          row['user_a'] == currentUser.id ? row['user_b'] : row['user_a'];
      final profileRow = await supabase
          .from('profiles')
          .select()
          .eq('id', otherId)
          .maybeSingle();
      if (profileRow != null) {
        matches.add(Match(
          user: _profileFromRow(profileRow),
          matchedAt: DateTime.parse(row['matched_at']),
        ));
      }
    }
    return matches;
  }

  static UserInput _profileFromRow(Map<String, dynamic> row) {
    return UserInput(
      id: row['id'],
      name: row['name'] ?? '',
      age: row['age'] ?? 0,
      city: row['city'] ?? '',
      gender: row['gender'] ?? '',
      relationshipGoal: row['relationship_goal'] ?? '',
      about: row['about'] ?? '',
      expectation: row['expectation'] ?? '',
      interests: List<String>.from(row['interests'] ?? []),
      traits: List<String>.from(row['traits'] ?? []),
      partnerTraits: List<String>.from(row['partner_traits'] ?? []),
      appearance: List<String>.from(row['appearance'] ?? []),
      networkPhotoUrls: List<String>.from(row['photo_urls'] ?? []),
    );
  }
}