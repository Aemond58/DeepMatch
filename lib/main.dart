import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_input.dart';
import 'models/match.dart';
import 'screens/registration_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';
import 'theme.dart';

const bool kShowBots = bool.fromEnvironment('SHOW_BOTS', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepMatch',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;
  UserInput? _currentUser;
  bool _loading = true;
  bool _showOnboarding = true;
  bool _isAuthenticated = false;
  final List<LikeHistoryItem> _history = [];
  final List<Match> _matches = [];
  int _unreadMatches = 0;
  FilterData _filterData = FilterData();
  dynamic _matchesChannel;

  List<UserInput> _realProfiles = [];

  List<UserInput> get _allProfiles => _realProfiles;

  int _profileIndex = 0;

  List<UserInput> get _filteredProfiles {
    return _allProfiles.where((p) {
      if (_filterData.city.isNotEmpty &&
          !p.city.toLowerCase().contains(_filterData.city.toLowerCase())) {
        return false;
      }
      if (_filterData.gender.isNotEmpty && p.gender != _filterData.gender) {
        return false;
      }
      if (_filterData.relationshipGoal.isNotEmpty &&
          p.relationshipGoal != _filterData.relationshipGoal) {
        return false;
      }
      if (_filterData.traits.isNotEmpty) {
        if (!_filterData.traits.any((t) => p.traits.contains(t))) return false;
      }
      if (_filterData.interests.isNotEmpty) {
        if (!_filterData.interests.any((t) => p.interests.contains(t))) {
          return false;
        }
      }
      if (_filterData.appearance.isNotEmpty) {
        if (!_filterData.appearance.any((a) => p.appearance.contains(a))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _matchesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _init() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      setState(() {
        _isAuthenticated = false;
        _loading = false;
      });
      return;
    }
    _isAuthenticated = true;
    await _loadUser();
  }

  Future<void> _onAuthenticated() async {
    setState(() {
      _isAuthenticated = true;
      _loading = true;
    });
    await _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;

    UserInput? remoteUser;
    try {
      remoteUser = await SupabaseService.loadOwnProfile();
    } catch (_) {
      remoteUser = null;
    }

    if (remoteUser != null) {
      await prefs.setString('current_user', jsonEncode(remoteUser.toJson()));
      await prefs.setBool('onboarded', true);
      setState(() {
        _currentUser = remoteUser;
        _showOnboarding = false;
        _loading = false;
      });
    } else {
      final json = prefs.getString('current_user');
      if (json != null) {
        setState(() {
          _currentUser = UserInput.fromJson(jsonDecode(json));
          _showOnboarding = false;
          _loading = false;
        });
      } else {
        setState(() {
          _showOnboarding = !onboarded;
          _loading = false;
        });
      }
    }

    _loadRealProfiles();
    _loadMatches();
    _subscribeToMatches();
  }

  Future<void> _loadRealProfiles() async {
    try {
      final profiles = await SupabaseService.loadOtherProfiles(includeBots: kShowBots);
      if (mounted) {
        setState(() {
          _realProfiles = profiles;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await SupabaseService.loadMatches();
      if (mounted) {
        setState(() {
          _matches
            ..clear()
            ..addAll(matches);
        });
      }
    } catch (_) {}
  }

  void _subscribeToMatches() {
    _matchesChannel = SupabaseService.subscribeToNewMatches((match) {
      if (!mounted) return;
      if (_matches.any((m) => m.id == match.id)) return;
      setState(() {
        _matches.add(match);
        _unreadMatches++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💜 Это match! Вы с ${match.user.name} понравились друг другу'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Написать',
            textColor: Colors.white,
            onPressed: () => setState(() => _currentTab = 2),
          ),
        ),
      );
    });
  }

  Future<void> _saveUser(UserInput user) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _loading = true);

    List<String> photoUrls = List.from(user.networkPhotoUrls);
    try {
      if (user.photos.isNotEmpty) {
        final uploaded = await SupabaseService.uploadPhotos(user.photos);
        photoUrls = uploaded;
      }
      final userForCloud = UserInput(
        name: user.name,
        age: user.age,
        city: user.city,
        gender: user.gender,
        relationshipGoal: user.relationshipGoal,
        about: user.about,
        expectation: user.expectation,
        interests: user.interests,
        traits: user.traits,
        partnerTraits: user.partnerTraits,
        appearance: user.appearance,
        networkPhotoUrls: photoUrls,
      );
      await SupabaseService.saveProfile(userForCloud, photoUrls);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось сохранить в облако: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    final localUser = UserInput(
      id: supabase.auth.currentUser?.id,
      name: user.name,
      age: user.age,
      city: user.city,
      gender: user.gender,
      relationshipGoal: user.relationshipGoal,
      about: user.about,
      expectation: user.expectation,
      interests: user.interests,
      traits: user.traits,
      partnerTraits: user.partnerTraits,
      appearance: user.appearance,
      photos: user.photos,
      networkPhotoUrls: photoUrls,
    );

    await prefs.setString('current_user', jsonEncode(localUser.toJson()));
    await prefs.setBool('onboarded', true);

    setState(() {
      _currentUser = localUser;
      _loading = false;
      if (user.city.isNotEmpty) {
        _filterData = FilterData(
          city: user.city,
          traits: _filterData.traits,
          interests: _filterData.interests,
          appearance: _filterData.appearance,
          gender: _filterData.gender,
          relationshipGoal: _filterData.relationshipGoal,
        );
      }
    });
  }

  Future<void> _logout() async {
    _matchesChannel?.unsubscribe();
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    setState(() {
      _isAuthenticated = false;
      _currentUser = null;
      _realProfiles = [];
      _profileIndex = 0;
      _history.clear();
      _matches.clear();
      _unreadMatches = 0;
    });
  }

  Future<void> _onLike() async {
    final profiles = _filteredProfiles;
    if (_profileIndex >= profiles.length) return;
    final profile = profiles[_profileIndex];
    setState(() {
      _history.insert(0, LikeHistoryItem(
        user: profile,
        passedAt: DateTime.now(),
        liked: true,
      ));
      _profileIndex++;
    });

    if (profile.id == null) return;

    String? matchId;
    try {
      matchId = await SupabaseService.likeUser(profile.id!);
    } catch (_) {
      return;
    }

    if (matchId != null && mounted) {
      if (_matches.any((m) => m.id == matchId)) return;
      final match = Match(id: matchId, user: profile, matchedAt: DateTime.now());
      setState(() {
        _matches.add(match);
        _unreadMatches++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💜 Это match! Вы с ${profile.name} понравились друг другу'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Написать',
            textColor: Colors.white,
            onPressed: () => setState(() => _currentTab = 2),
          ),
        ),
      );
    }
  }

  void _onPass() {
    final profiles = _filteredProfiles;
    if (_profileIndex >= profiles.length) return;
    setState(() {
      _history.insert(0, LikeHistoryItem(
        user: profiles[_profileIndex],
        passedAt: DateTime.now(),
        liked: false,
      ));
      _profileIndex++;
    });
  }

  void _onHistoryLike(LikeHistoryItem item) {
    setState(() {
      final index = _history.indexOf(item);
      _history[index] = LikeHistoryItem(
        user: item.user,
        passedAt: item.passedAt,
        liked: true,
      );
    });
  }

  void _openFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => FilterSheet(
          current: _filterData,
          onApply: (data) => setState(() {
            _filterData = data;
            _profileIndex = 0;
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!_isAuthenticated) {
      return AuthScreen(onAuthenticated: _onAuthenticated);
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        onStart: () => setState(() => _showOnboarding = false),
      );
    }

    if (_currentUser == null) {
      return RegistrationScreen(
        onComplete: (user) => _saveUser(user),
      );
    }

    final profiles = _filteredProfiles;

    final exploreTab = Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Explore',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune, color: AppColors.textPrimary),
                if (!_filterData.isEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _openFilters(context),
          ),
        ],
      ),
      body: _profileIndex < profiles.length
          ? ProfileScreen(
              user: profiles[_profileIndex],
              onLike: _onLike,
              onPass: _onPass,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😴', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    'Пока никого нет',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (!_filterData.isEmpty)
                    TextButton(
                      onPressed: () => setState(() {
                        _filterData = FilterData();
                        _profileIndex = 0;
                      }),
                      child: const Text(
                        'Сбросить фильтры',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
    );

    final tabs = [
      exploreTab,
      HistoryScreen(history: _history, onLike: _onHistoryLike),
      ChatsScreen(matches: _matches),
      MyProfileScreen(
        user: _currentUser!,
        onEdit: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationScreen(
              existingUser: _currentUser,
              onComplete: (user) {
                _saveUser(user);
                Navigator.pop(context);
              },
            ),
          ),
        ),
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      body: tabs[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) {
          setState(() {
            _currentTab = i;
            if (i == 2) _unreadMatches = 0;
          });
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'История',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _unreadMatches > 0,
              label: Text('$_unreadMatches'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: _unreadMatches > 0,
              label: Text('$_unreadMatches'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Чаты',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Я',
          ),
        ],
      ),
    );
  }
}