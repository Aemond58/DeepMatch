import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/user_input.dart';
import 'supabase_config.dart';

class SupabaseService {
  static Future<List<String>> uploadPhotos(List<Uint8List> photos) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final session = supabase.auth.currentSession;
    if (session == null) throw Exception('Нет сессии');

    final List<String> urls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < photos.length; i++) {
      final path = '${user.id}/${timestamp}_$i.jpg';
      final base64Data = base64Encode(photos[i]);

      final response = await http.post(
        Uri.parse('$supabaseUrl/storage/v1/object/avatars/$path'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
          'x-upsert': 'true',
        },
        body: jsonEncode({
          'data': base64Data,
          'mimeType': 'image/jpeg',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка загрузки фото: ${response.body}');
      }

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

  static UserInput _profileFromRow(Map<String, dynamic> row) {
    return UserInput(
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