import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/match.dart';
import '../theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final Match match;
  final Function(String) onSend;

  const ChatDetailScreen({super.key, required this.match, required this.onSend});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  static const _autoReplies = [
    'Привет! Рада познакомиться 😊',
    'О, интересно! Расскажи больше о себе',
    'Привет! Ты кажешься интересным человеком',
    'Хей! Как твой день?',
    'Привет 👋 Чем занимаешься?',
  ];

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();
    final isFirst = widget.match.messages.where((m) => m.isMe).isEmpty;
    setState(() {
      widget.match.messages.add(ChatMessage(text: text, isMe: true, sentAt: DateTime.now()));
    });
    widget.onSend(text);
    _scrollToBottom();

    if (isFirst) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _isTyping = true);
        _scrollToBottom();
      });
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          widget.match.messages.add(ChatMessage(
            text: _autoReplies[Random().nextInt(_autoReplies.length)],
            isMe: false,
            sentAt: DateTime.now(),
          ));
        });
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs = widget.match.messages;
    final itemCount = msgs.length + (_isTyping ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                border: Border.all(color: AppColors.primaryDim),
                image: widget.match.user.photoProvider != null
                    ? DecorationImage(image: widget.match.user.photoProvider!, fit: BoxFit.cover)
                    : null,
              ),
              child: widget.match.user.photoProvider == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.match.user.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                if (_isTyping)
                  const Text('печатает...',
                      style: TextStyle(color: AppColors.primary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.isEmpty && !_isTyping
                ? Center(
                    child: Text('Напиши первым ${widget.match.user.name} 👋',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: itemCount,
                    itemBuilder: (_, i) {
                      if (_isTyping && i == msgs.length) return const _TypingBubble();
                      final msg = msgs[i];
                      return Align(
                        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: msg.isMe ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: msg.isMe
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : null,
                          ),
                          child: Text(msg.text,
                              style: TextStyle(
                                  color: msg.isMe ? Colors.white : AppColors.textPrimary,
                                  fontSize: 15, height: 1.4)),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> {
  int _step = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _step = (_step + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(18)),
        child: Text('Печатает${'.' * _step}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      ),
    );
  }
}
