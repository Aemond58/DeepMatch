import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserInput {
  final String name;
  final int age;
  final String city;
  final String gender;
  final String relationshipGoal;
  final String about;
  final String expectation;
  final List<String> interests;
  final List<String> traits;
  final List<String> partnerTraits;
  final List<String> appearance;
  final List<Uint8List> photos;
  final List<String> networkPhotoUrls;
  final List<String> assetPhotoPaths;

  UserInput({
    required this.name,
    required this.age,
    required this.city,
    this.gender = '',
    required this.relationshipGoal,
    required this.about,
    required this.expectation,
    required this.interests,
    required this.traits,
    required this.partnerTraits,
    this.appearance = const [],
    this.photos = const [],
    this.networkPhotoUrls = const [],
    this.assetPhotoPaths = const [],
  });

  ImageProvider? get photoProvider {
    if (photos.isNotEmpty) return MemoryImage(photos.first);
    if (assetPhotoPaths.isNotEmpty) return AssetImage(assetPhotoPaths.first);
    if (networkPhotoUrls.isNotEmpty) return NetworkImage(networkPhotoUrls.first);
    return null;
  }

  List<ImageProvider> get allPhotoProviders {
    if (photos.isNotEmpty) {
      return photos.map<ImageProvider>((b) => MemoryImage(b)).toList();
    }
    if (assetPhotoPaths.isNotEmpty) {
      return assetPhotoPaths.map<ImageProvider>((p) => AssetImage(p)).toList();
    }
    if (networkPhotoUrls.isNotEmpty) {
      return networkPhotoUrls.map<ImageProvider>((u) => NetworkImage(u)).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'city': city,
        'gender': gender,
        'relationshipGoal': relationshipGoal,
        'about': about,
        'expectation': expectation,
        'interests': interests,
        'traits': traits,
        'partnerTraits': partnerTraits,
        'appearance': appearance,
        'photos': photos.map((b) => base64Encode(b)).toList(),
        'networkPhotoUrls': networkPhotoUrls,
        'assetPhotoPaths': assetPhotoPaths,
      };

  factory UserInput.fromJson(Map<String, dynamic> json) {
    // Backward compat: old single-photo format
    List<Uint8List> photos = [];
    if (json['photos'] != null) {
      photos = (json['photos'] as List<dynamic>)
          .map((b) => base64Decode(b as String))
          .toList();
    } else if (json['photoBytes'] != null) {
      photos = [base64Decode(json['photoBytes'] as String)];
    }

    List<String> networkPhotoUrls = [];
    if (json['networkPhotoUrls'] != null) {
      networkPhotoUrls = List<String>.from(json['networkPhotoUrls']);
    } else if (json['networkPhotoUrl'] != null) {
      networkPhotoUrls = [json['networkPhotoUrl'] as String];
    }

    return UserInput(
      name: json['name'],
      age: json['age'],
      city: json['city'],
      gender: json['gender'] ?? '',
      relationshipGoal: json['relationshipGoal'],
      about: json['about'],
      expectation: json['expectation'],
      interests: List<String>.from(json['interests']),
      traits: List<String>.from(json['traits']),
      partnerTraits: List<String>.from(json['partnerTraits']),
      appearance: json['appearance'] != null
          ? List<String>.from(json['appearance'])
          : [],
      photos: photos,
      networkPhotoUrls: networkPhotoUrls,
      assetPhotoPaths: json['assetPhotoPaths'] != null
          ? List<String>.from(json['assetPhotoPaths'])
          : [],
    );
  }
}
