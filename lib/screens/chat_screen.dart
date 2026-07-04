import 'package:flutter/material.dart';
import '../models/match.dart';
import '../theme.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatelessWidget {
  final List<Match> matches;

  const ChatsScreen({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Чаты',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w500)),
      ),
      body: matches.isEmpty
          ? const Center(
              child: Text('Пока нет совпадений 💬',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            )
          : ListView.builder(
              itemCount: matches.length,
              itemBuilder: (_, i) {
                final match = matches[i];
                final lastMsg = match.messages.isNotEmpty ? match.messages.last.text : 'Напишите первым!';
                final hasUnread = match.messages.isNotEmpty && !match.messages.last.isMe;
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(match: match),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.card,
                            border: Border.all(color: AppColors.primaryDim, width: 1.5),
                            image: match.user.photoProvider != null
                                ? DecorationImage(image: match.user.photoProvider!, fit: BoxFit.cover)
                                : null,
                          ),
                          child: match.user.photoProvider == null
                              ? const Icon(Icons.person, color: AppColors.primary, size: 26)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(match.user.name,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(lastMsg,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: hasUnread ? AppColors.primary : AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}