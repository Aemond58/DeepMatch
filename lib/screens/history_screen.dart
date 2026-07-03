import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../theme.dart';

class LikeHistoryItem {
  final UserInput user;
  final DateTime passedAt;
  final bool liked;

  LikeHistoryItem({
    required this.user,
    required this.passedAt,
    required this.liked,
  });

  bool get canStillLike => DateTime.now().difference(passedAt).inDays < 10;
  int get daysLeft => 10 - DateTime.now().difference(passedAt).inDays;
}

class HistoryScreen extends StatefulWidget {
  final List<LikeHistoryItem> history;
  final Function(LikeHistoryItem) onLike;

  const HistoryScreen({super.key, required this.history, required this.onLike});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final liked = widget.history.where((h) => h.liked).toList();
    final passed = widget.history.where((h) => !h.liked).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('История',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        children: [
          if (liked.isNotEmpty) ...[
            _buildSectionTitle('Лайки поставлены'),
            ...liked.map((item) => _buildHistoryItem(item)),
          ],
          if (passed.isNotEmpty) ...[
            _buildSectionTitle('Пропущено'),
            ...passed.map((item) => _buildHistoryItem(item)),
          ],
          if (widget.history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Пока пусто',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildHistoryItem(LikeHistoryItem item) {
    final canLike = !item.liked && item.canStillLike;
    final expired = !item.liked && !item.canStillLike;

    return Opacity(
      opacity: expired ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _ProfileViewScreen(user: item.user)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(color: AppColors.primaryDim, width: 1.5),
                  image: item.user.photoProvider != null
                      ? DecorationImage(image: item.user.photoProvider!, fit: BoxFit.cover)
                      : null,
                ),
                child: item.user.photoProvider == null
                    ? const Icon(Icons.person, color: AppColors.primary, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.user.name}, ${item.user.age}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    if (!item.liked && item.canStillLike)
                      Text('⏱ ${item.daysLeft} дн. чтобы вернуться',
                          style: const TextStyle(fontSize: 11, color: AppColors.warning)),
                    if (expired)
                      const Text('Срок истёк',
                          style: TextStyle(fontSize: 11, color: AppColors.dislike)),
                    if (item.liked)
                      const Text('Лайк поставлен',
                          style: TextStyle(fontSize: 11, color: AppColors.like)),
                  ],
                ),
              ),
              if (canLike)
                GestureDetector(
                  onTap: () {
                    widget.onLike(item);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Text('Лайкнуть',
                        style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                ),
              if (item.liked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.primaryDim,
                  ),
                  child: const Text('Лайк ✓',
                      style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileViewScreen extends StatelessWidget {
  final UserInput user;

  const _ProfileViewScreen({required this.user});

  Widget _buildSection(String label, Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(user.name,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 300,
              child: user.photoProvider != null
                  ? Image(image: user.photoProvider!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E1A40), Color(0xFF0E1A30)],
                        ),
                      ),
                      child: const Center(
                          child: Icon(Icons.person, size: 80, color: AppColors.border)),
                    ),
            ),
            if (user.about.isNotEmpty)
              _buildSection('О СЕБЕ',
                  Text(user.about, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5))),
            if (user.relationshipGoal.isNotEmpty)
              _buildSection('ТИП ОТНОШЕНИЙ',
                  Text(user.relationshipGoal, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
            if (user.interests.isNotEmpty) _buildSection('ИНТЕРЕСЫ', _buildTags(user.interests)),
            if (user.appearance.isNotEmpty) _buildSection('ВНЕШНОСТЬ', _buildTags(user.appearance)),
            if (user.expectation.isNotEmpty)
              _buildSection('ЧЕГО ОЖИДАЕТ',
                  Text(user.expectation, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5))),
            if (user.partnerTraits.isNotEmpty)
              _buildSection('ВАЖНО В ПАРТНЁРЕ', _buildTags(user.partnerTraits)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
