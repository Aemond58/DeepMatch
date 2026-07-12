import 'package:flutter/material.dart';
import '../models/user_input.dart';
import '../theme.dart';
import '../supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserInput user;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final Function(int)? onRate;
  final bool readOnly;

  const ProfileScreen({
    super.key,
    required this.user,
    this.onLike,
    this.onPass,
    this.onRate,
    this.readOnly = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _photoIndex = 0;
  int? _rating;
  final PageController _pageController = PageController();
  bool _blocked = false;
  bool _blockLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.readOnly && widget.user.id != null) {
      _checkBlocked();
    }
  }

  Future<void> _checkBlocked() async {
    final blocked = await SupabaseService.isBlocked(widget.user.id!);
    if (mounted) setState(() => _blocked = blocked);
  }

  Future<void> _toggleBlock() async {
    if (widget.user.id == null) return;
    setState(() => _blockLoading = true);
    try {
      if (_blocked) {
        await SupabaseService.unblockUser(widget.user.id!);
      } else {
        await SupabaseService.blockUser(widget.user.id!);
      }
      if (mounted) setState(() => _blocked = !_blocked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _blockLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSection(String label, Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
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

  Widget _buildPhotoArea() {
    final photos = widget.user.allPhotoProviders;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 380,
          child: photos.isEmpty
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A181C), Color(0xFF14090C)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 80, color: AppColors.border),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _photoIndex = i),
                  itemBuilder: (_, i) => Image(
                    image: photos[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Center(
                          child: Icon(Icons.person, size: 80, color: AppColors.border)),
                    ),
                  ),
                ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            top: 14, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                final active = i == _photoIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 20 : 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: active
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 6)]
                        : null,
                  ),
                );
              }),
            ),
          ),
        Positioned(
          bottom: 16, left: 16, right: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.user.name}, ${widget.user.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              if (widget.user.city.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text(widget.user.city,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
            ],
          ),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 18, right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_photoIndex + 1}/${photos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Оцени внешность',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_rating != null)
                Text(
                  '$_rating / 10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _ratingColor(_rating!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (i) {
              final score = i + 1;
              final isSelected = _rating == score;
              final color = _ratingColor(score);
              return GestureDetector(
                onTap: () {
                  setState(() => _rating = score);
                  widget.onRate?.call(score);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _ratingColor(int score) {
    if (score <= 3) return const Color(0xFFE24B4A);
    if (score <= 6) return const Color(0xFFEF9F27);
    return const Color(0xFF1D9E75);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: widget.readOnly
          ? AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(user.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w500)),
              actions: [
                if (_blockLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      _blocked ? Icons.block : Icons.block_outlined,
                      color: _blocked ? AppColors.dislike : AppColors.textSecondary,
                    ),
                    tooltip: _blocked ? 'Разблокировать' : 'Заблокировать',
                    onPressed: _toggleBlock,
                  ),
              ],
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoArea(),
                  if (user.about.isNotEmpty)
                    _buildSection('О СЕБЕ',
                        Text(user.about, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6))),
                  if (user.relationshipGoal.isNotEmpty)
                    _buildSection('ТИП ОТНОШЕНИЙ',
                        Text(user.relationshipGoal, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
                  if (user.interests.isNotEmpty)
                    _buildSection('ИНТЕРЕСЫ', _buildTags(user.interests)),
                  if (user.appearance.isNotEmpty)
                    _buildSection('ВНЕШНОСТЬ', _buildTags(user.appearance)),
                  if (user.expectation.isNotEmpty)
                    _buildSection('ЧЕГО ОЖИДАЕТ',
                        Text(user.expectation, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6))),
                  if (user.partnerTraits.isNotEmpty)
                    _buildSection('ВАЖНО В ПАРТНЁРЕ', _buildTags(user.partnerTraits)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (!widget.readOnly) _buildRatingBar(),
          if (!widget.readOnly)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                      icon: Icons.close,
                      color: AppColors.dislike,
                      size: 60,
                      onTap: widget.onPass ?? () {}),
                  _ActionButton(
                      icon: Icons.favorite,
                      color: Colors.white,
                      backgroundColor: AppColors.primary,
                      size: 72,
                      onTap: widget.onLike ?? () {},
                      glow: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double size;
  final VoidCallback onTap;
  final bool glow;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.backgroundColor,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppColors.card,
          border: backgroundColor == null
              ? Border.all(color: color.withOpacity(0.6), width: 1.5)
              : null,
          boxShadow: glow
              ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2)]
              : null,
        ),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }
}