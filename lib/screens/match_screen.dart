import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../theme.dart';

class MatchScreen extends StatelessWidget {
  final UserInput myUser;
  final UserInput matchedUser;
  final VoidCallback onChat;
  final VoidCallback onContinue;

  const MatchScreen({
    super.key,
    required this.myUser,
    required this.matchedUser,
    required this.onChat,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              '🎉',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Это match!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Вы и ${matchedUser.name} понравились друг другу',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(myUser),
                const SizedBox(width: 24),
                const Icon(Icons.favorite, color: Colors.white, size: 32),
                const SizedBox(width: 24),
                _buildAvatar(matchedUser),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Написать',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onContinue,
                    child: const Text(
                      'Продолжить просмотр',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserInput user) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        image: user.photoProvider != null
            ? DecorationImage(
                image: user.photoProvider!,
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.white24,
      ),
      child: user.photoProvider == null
          ? const Icon(Icons.person, color: Colors.white, size: 40)
          : null,
    );
  }
}