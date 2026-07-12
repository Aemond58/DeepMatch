import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../theme.dart';

class MyProfileScreen extends StatelessWidget {
  final UserInput user;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const MyProfileScreen({super.key, required this.user, required this.onEdit, required this.onLogout});

  Widget _buildSection(String label, Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(tag,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Мой профиль',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: onEdit,
            child: const Text('Изменить', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A181C), Color(0xFF14090C)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2.5),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16),
                          ],
                          image: user.photoProvider != null
                              ? DecorationImage(image: user.photoProvider!, fit: BoxFit.cover)
                              : null,
                          color: AppColors.card,
                        ),
                        child: user.photoProvider == null
                            ? const Icon(Icons.person, size: 40, color: AppColors.textSecondary)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text('${user.name}, ${user.age}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
                      if (user.city.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text(user.city,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                    ],
                  ),
                ),
                if (user.about.isNotEmpty)
                  _buildSection('О СЕБЕ',
                      Text(user.about,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6))),
                if (user.relationshipGoal.isNotEmpty)
                  _buildSection('ТИП ОТНОШЕНИЙ',
                      Text(user.relationshipGoal,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
                if (user.gender.isNotEmpty)
                  _buildSection('ПОЛ',
                      Text(user.gender,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
                if (user.interests.isNotEmpty) _buildSection('ИНТЕРЕСЫ', _buildTags(user.interests)),
                if (user.appearance.isNotEmpty) _buildSection('ВНЕШНОСТЬ', _buildTags(user.appearance)),
                if (user.expectation.isNotEmpty)
                  _buildSection('ЧЕГО ОЖИДАЮ',
                      Text(user.expectation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6))),
                if (user.partnerTraits.isNotEmpty)
                  _buildSection('ВАЖНО В ПАРТНЁРЕ', _buildTags(user.partnerTraits)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, color: AppColors.dislike),
                      label: const Text('Выйти из аккаунта',
                          style: TextStyle(color: AppColors.dislike, fontWeight: FontWeight.w500)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.dislike),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}