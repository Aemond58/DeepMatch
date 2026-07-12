import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/match.dart';
import '../supabase_service.dart';
import '../theme.dart';
import 'profile_screen.dart';

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
  bool _sending = false;
  Uint8List? _pendingImage;
  dynamic _channel;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _channel = SupabaseService.subscribeToMessages(
      widget.match.id,
      (msg) {
        if (!mounted) return;
        if (msg.isMe) return;
        setState(() {
          widget.match.messages.add(msg);
        });
        _scrollToBottom();
      },
      (deletedId) {
        if (!mounted) return;
        setState(() {
          widget.match.messages.removeWhere((m) => m.id == deletedId);
        });
      },
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _pendingImage = bytes);
  }

  void _cancelPendingImage() {
    setState(() => _pendingImage = null);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final image = _pendingImage;

    if (text.isEmpty && image == null) return;

    _controller.clear();
    setState(() => _pendingImage = null);

    if (_sending) return;
    setState(() => _sending = true);

    try {
      if (image != null) {
        final imageUrl = await SupabaseService.uploadChatImage(image, widget.match.id);
        final id = await SupabaseService.sendMessage(
          widget.match.id,
          text.isNotEmpty ? text : null,
          imageUrl: imageUrl,
        );
        setState(() {
          widget.match.messages.add(ChatMessage(
            id: id,
            text: text.isNotEmpty ? text : null,
            imageUrl: imageUrl,
            isMe: true,
            sentAt: DateTime.now(),
          ));
        });
      } else {
        final id = await SupabaseService.sendMessage(widget.match.id, text);
        setState(() {
          widget.match.messages.add(ChatMessage(id: id, text: text, isMe: true, sentAt: DateTime.now()));
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    if (msg.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить сообщение?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Сообщение исчезнет у обоих собеседников.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.dislike)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      widget.match.messages.removeWhere((m) => m.id == msg.id);
    });

    try {
      await SupabaseService.deleteMessage(msg.id!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось удалить: $e')),
        );
      }
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: widget.match.user,
          readOnly: true,
        ),
      ),
    );
  }

  void _openFullImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    final hasText = msg.text != null && msg.text!.isNotEmpty;

    final bubble = Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (hasImage)
              GestureDetector(
                onTap: () => _openFullImage(msg.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    msg.imageUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: AppColors.card,
                        child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary)),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 150,
                      color: AppColors.card,
                      child: const Center(child: Icon(Icons.broken_image, color: AppColors.textSecondary)),
                    ),
                  ),
                ),
              ),
            if (hasImage && hasText) const SizedBox(height: 4),
            if (hasText)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isMe ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: msg.isMe
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Linkify(
                  text: msg.text!,
                  onOpen: (link) async {
                    final uri = Uri.parse(link.url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: TextStyle(
                      color: msg.isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 15, height: 1.4),
                  linkStyle: TextStyle(
                      color: msg.isMe ? Colors.white : AppColors.primary,
                      fontSize: 15, height: 1.4,
                      decoration: TextDecoration.underline),
                ),
              ),
          ],
        ),
      ),
    );

    if (!msg.isMe || msg.id == null) return bubble;

    return GestureDetector(
      onLongPress: () => _deleteMessage(msg),
      child: bubble,
    );
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
        title: GestureDetector(
          onTap: _openProfile,
          child: Row(
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
                        reverse: true,
                        itemCount: msgs.length,
                        itemBuilder: (_, i) => _buildMessageBubble(msgs[msgs.length - 1 - i]),
                      ),
          ),
          if (_pendingImage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              color: AppColors.surface,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _pendingImage!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: _cancelPendingImage,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
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
                IconButton(
                  onPressed: _sending ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                ),
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
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
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