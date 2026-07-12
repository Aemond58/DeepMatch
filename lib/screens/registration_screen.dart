import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_input.dart';
import '../widgets/selectable_chips.dart';
import '../theme.dart';
import '../screens/filter_screen.dart' show appearanceOptions, allInterests, allTraits;

class RegistrationScreen extends StatefulWidget {
  final Function(UserInput) onComplete;
  final UserInput? existingUser;

  const RegistrationScreen({
    super.key,
    required this.onComplete,
    this.existingUser,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _pageController = PageController();
  int _page = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _cityController;
  late final TextEditingController _aboutController;
  late final TextEditingController _expectationController;

  late String _selectedGoal;
  late String _selectedGender;
  late List<String> _selectedInterests;
  late List<String> _selectedTraits;
  late List<String> _selectedPartnerTraits;
  late List<String> _selectedAppearance;
  late List<Uint8List> _photos;

  static const int _maxPhotos = 5;

  final List<String> _genders = ['Мужской', 'Женский'];

  final List<String> _goals = [
    'Серьёзные отношения',
    'Встречаться без обязательств',
    'Флирт и общение',
    'Дружба',
    'Пока не знаю',
  ];

final List<String> _interests = allInterests;
  final List<String> _traits = allTraits;
  final List<String> _partnerTraits = allTraits;

  List<String> get _appearanceList => appearanceOptions(_selectedGender);

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    _nameController = TextEditingController(text: u?.name ?? '');
    _ageController = TextEditingController(text: u != null ? '${u.age}' : '');
    _cityController = TextEditingController(text: u?.city ?? '');
    _aboutController = TextEditingController(text: u?.about ?? '');
    _expectationController = TextEditingController(text: u?.expectation ?? '');
    _selectedGoal = u?.relationshipGoal ?? '';
    _selectedGender = u?.gender ?? '';
    _selectedInterests = List.from(u?.interests ?? []);
    _selectedTraits = List.from(u?.traits ?? []);
    _selectedPartnerTraits = List.from(u?.partnerTraits ?? []);
    _selectedAppearance = List.from(u?.appearance ?? []);
    _photos = List.from(u?.photos ?? []);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _aboutController.dispose();
    _expectationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      if (index < _photos.length) {
        _photos[index] = bytes;
      } else {
        _photos.add(bytes);
      }
    });
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  void _nextPage() {
    if (_nameController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Заполни имя, возраст и пол'),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _save() {
    if (_nameController.text.isNotEmpty && _ageController.text.isNotEmpty) {
      widget.onComplete(UserInput(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        city: _cityController.text.trim(),
        gender: _selectedGender,
        relationshipGoal: _selectedGoal,
        about: _aboutController.text.trim(),
        expectation: _expectationController.text.trim(),
        interests: _selectedInterests,
        traits: _selectedTraits,
        partnerTraits: _selectedPartnerTraits,
        appearance: _selectedAppearance,
        photos: _photos,
      ));
    }
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildChipSelector(List<String> options, String selected, void Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)]
                  : null,
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_maxPhotos, (i) {
            final hasPhoto = i < _photos.length;
            final isAddSlot = i == _photos.length && _photos.length < _maxPhotos;
            final isDisabled = !hasPhoto && !isAddSlot;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _maxPhotos - 1 ? 6 : 0),
                child: GestureDetector(
                  onTap: (hasPhoto || isAddSlot) ? () => _pickPhoto(i) : null,
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDisabled ? AppColors.bg : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasPhoto
                                  ? AppColors.primary
                                  : isAddSlot
                                      ? AppColors.primaryDim
                                      : AppColors.border,
                              width: hasPhoto ? 1.5 : 1,
                            ),
                            image: hasPhoto
                                ? DecorationImage(
                                    image: MemoryImage(_photos[i]),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: !hasPhoto
                              ? Center(
                                  child: Icon(
                                    isAddSlot ? Icons.add_a_photo : Icons.add,
                                    color: isDisabled ? AppColors.border : AppColors.primary,
                                    size: 22,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (hasPhoto)
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(i),
                            child: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      if (i == 0 && hasPhoto)
                        Positioned(
                          bottom: 4, left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Главное',
                                style: TextStyle(color: Colors.white, fontSize: 9)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text('${_photos.length} / $_maxPhotos фото',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 6)]
                : null,
          ),
        );
      }),
    );
  }

  // ── Page 1 ──────────────────────────────────────────
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          _buildLabel('ФОТО (до 5)'),
          _buildPhotoGrid(),

          _buildLabel('ИМЯ'),
          _buildTextField(_nameController, 'Как тебя зовут?'),

          _buildLabel('ПОЛ'),
          const SizedBox(height: 4),
          _buildChipSelector(_genders, _selectedGender, (g) {
            setState(() {
              _selectedGender = g;
              // Reset appearance when gender changes
              _selectedAppearance.clear();
            });
          }),

          _buildLabel('ВОЗРАСТ'),
          _buildTextField(_ageController, 'Сколько тебе лет?',
              keyboardType: TextInputType.number),

          _buildLabel('ГОРОД'),
          _buildTextField(_cityController, 'Где ты живёшь?'),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shadowColor: AppColors.primary.withOpacity(0.5),
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Далее', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Page 2 ──────────────────────────────────────────
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          _buildLabel('О СЕБЕ'),
          _buildTextField(_aboutController, 'Расскажи о себе...', maxLines: 3),

          _buildLabel('ТИП ОТНОШЕНИЙ'),
          const SizedBox(height: 4),
          _buildChipSelector(_goals, _selectedGoal,
              (g) => setState(() => _selectedGoal = g)),

          _buildLabel('ЧЕГО ЖДЁШЬ ОТ ПАРТНЁРА'),
          _buildTextField(_expectationController, 'Опиши чего ты ожидаешь...', maxLines: 3),

          _buildLabel('ТВОИ ИНТЕРЕСЫ'),
          SelectableChips(
            items: _interests,
            selected: _selectedInterests,
            onChanged: (val) => setState(() => _selectedInterests = val),
          ),

          _buildLabel('ТВОИ ЧЕРТЫ ХАРАКТЕРА'),
          SelectableChips(
            items: _traits,
            selected: _selectedTraits,
            onChanged: (val) => setState(() => _selectedTraits = val),
          ),

          _buildLabel('ВАЖНЫЕ ЧЕРТЫ В ПАРТНЁРЕ'),
          SelectableChips(
            items: _partnerTraits,
            selected: _selectedPartnerTraits,
            onChanged: (val) => setState(() => _selectedPartnerTraits = val),
          ),

          _buildLabel('ТВОЯ ВНЕШНОСТЬ'),
          SelectableChips(
            items: _appearanceList,
            selected: _selectedAppearance,
            onChanged: (val) => setState(() => _selectedAppearance = val),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shadowColor: AppColors.primary.withOpacity(0.5),
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Сохранить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: _page == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
              )
            : (widget.existingUser != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
        title: Text(
          widget.existingUser != null
              ? 'Редактировать профиль'
              : (_page == 0 ? 'Обо мне' : 'Предпочтения'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProgressDots(),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
       onPageChanged: (i) => WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _page = i)),
        children: [_buildPage1(), _buildPage2()],
      ),
    );
  }
}
