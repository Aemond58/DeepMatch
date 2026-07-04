import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match.dart';
import '../supabase_service.dart';
import '../theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final Match match;

  const ChatDetailScreen({super.key, required this.match});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  dynamic _channel;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _channel = SupabaseService.subscribeToMessages(widget.match.id, (msg) {
      if (!mounted) return;
      // не дублируем свои же сообщения (уже добавлены оптимистично при отправке)
      if (msg.isMe) return;
      setState(() {
        widget.match.messages.add(msg);
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final messages = await SupabaseService.loadMessages(widget.match.id);
      if (mounted) {
        setState(() {
          widget.match.messages = messages;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

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

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();

    setState(() {
      widget.match.messages.add(ChatMessage(text: text, isMe: true, sentAt: DateTime.now()));
    });
    _scrollToBottom();

    try {
      await SupabaseService.sendMessage(widget.match.id, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs = widget.match.messages;

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
            Text(widget.match.user.name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : msgs.isEmpty
                    ? Center(
                        child: Text('Напиши первым ${widget.match.user.name} 👋',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
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