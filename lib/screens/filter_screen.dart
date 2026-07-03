import 'package:flutter/material.dart';
import '../theme.dart';

class FilterData {
  final List<String> traits;
  final List<String> interests;
  final List<String> appearance;
  final String city;
  final String gender;
  final String relationshipGoal;
  final int ageMin;
  final int ageMax;

  FilterData({
    this.traits = const [],
    this.interests = const [],
    this.appearance = const [],
    this.city = '',
    this.gender = '',
    this.relationshipGoal = '',
    this.ageMin = 18,
    this.ageMax = 55,
  });

  bool get isEmpty =>
      traits.isEmpty &&
      interests.isEmpty &&
      appearance.isEmpty &&
      city.isEmpty &&
      gender.isEmpty &&
      relationshipGoal.isEmpty &&
      ageMin == 18 &&
      ageMax == 55;
}

List<String> appearanceOptions(String gender) {
  if (gender == 'Мужской') {
    return [
      'Высокий', 'Худощавый', 'Спортивное телосложение', 'Плотного телосложения',
      'Короткие волосы', 'Длинные волосы', 'Лысый',
      'Борода', 'Щетина', 'Усы',
      'Татуировки', 'Пирсинг', 'Очки',
    ];
  } else if (gender == 'Женский') {
    return [
      'Высокая', 'Миниатюрная', 'Спортивное телосложение', 'Пышные формы',
      'Короткие волосы', 'Длинные волосы', 'Кудрявые волосы', 'Крашеные волосы',
      'Татуировки', 'Пирсинг', 'Очки', 'Веснушки',
    ];
  }
  return [
    'Спортивное телосложение', 'Короткие волосы', 'Длинные волосы',
    'Татуировки', 'Пирсинг', 'Очки', 'Борода',
  ];
}

class FilterSheet extends StatefulWidget {
  final FilterData current;
  final Function(FilterData) onApply;

  const FilterSheet({
    super.key,
    required this.current,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late List<String> _traits;
  late List<String> _interests;
  late List<String> _appearance;
  late TextEditingController _cityController;
  late String _gender;
  late String _relationshipGoal;
  late RangeValues _ageRange;

  final List<String> _allTraits = [
    'Спокойный', 'Весёлый', 'Амбициозный', 'Добрый',
    'Честный', 'Творческий', 'Надёжный', 'Общительный',
    'Романтичный', 'Серьёзный', 'Спортивный', 'Интеллектуальный',
    'Заботливый', 'Независимый', 'Чуткий', 'Целеустремлённый',
  ];

  final List<String> _allInterests = [
    'Музыка', 'Кино', 'Спорт', 'Путешествия',
    'Готовка', 'Горы', 'Книги', 'Игры',
    'Искусство', 'Технологии', 'Танцы', 'Йога',
    'Фотография', 'Природа', 'Кофе', 'Животные',
    'Бег', 'Велоспорт', 'Театр', 'Саморазвитие',
  ];

  @override
  void initState() {
    super.initState();
    _traits = List.from(widget.current.traits);
    _interests = List.from(widget.current.interests);
    _appearance = List.from(widget.current.appearance);
    _cityController = TextEditingController(text: widget.current.city);
    _gender = widget.current.gender;
    _relationshipGoal = widget.current.relationshipGoal;
    _ageRange = RangeValues(
      widget.current.ageMin.toDouble(),
      widget.current.ageMax.toDouble(),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  List<String> get _currentAppearanceOptions => appearanceOptions(_gender);

  Widget _buildChips(List<String> all, List<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((item) {
        final isSelected = selected.contains(item);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              selected.remove(item);
            } else {
              selected.add(item);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 6)]
                  : null,
            ),
            child: Text(
              item,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
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
  }

  Widget _buildGenderChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Мужской', 'Женский'].map((g) {
        final isSelected = _gender == g;
        return GestureDetector(
          onTap: () => setState(() {
            _gender = isSelected ? '' : g;
            // Clean appearance that don't belong to new gender
            final opts = appearanceOptions(_gender);
            _appearance = _appearance.where((a) => opts.contains(a)).toList();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              g,
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

  Widget _buildGoalChips() {
    const goals = [
      'Серьёзные отношения',
      'Встречаться без обязательств',
      'Флирт и общение',
      'Дружба',
      'Пока не знаю',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((g) {
        final isSelected = _relationshipGoal == g;
        return GestureDetector(
          onTap: () => setState(() => _relationshipGoal = isSelected ? '' : g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              g,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _traits.clear();
                    _interests.clear();
                    _appearance.clear();
                    _cityController.clear();
                    _gender = '';
                    _relationshipGoal = '';
                    _ageRange = const RangeValues(18, 55);
                  }),
                  child: const Text('Сбросить',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age range
                  _buildLabel('ВОЗРАСТ'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_ageRange.start.round()} – ${_ageRange.end.round()} лет',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.card,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.2),
                      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 60,
                      divisions: 42,
                      onChanged: (v) => setState(() => _ageRange = v),
                    ),
                  ),

                  // Gender
                  _buildLabel('ПОЛ'),
                  _buildGenderChips(),

                  // City
                  _buildLabel('ГОРОД'),
                  TextField(
                    controller: _cityController,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Введи город...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // Relationship goal
                  _buildLabel('ТИП ОТНОШЕНИЙ'),
                  _buildGoalChips(),

                  // Traits
                  _buildLabel('ЧЕРТЫ ХАРАКТЕРА'),
                  _buildChips(_allTraits, _traits),

                  // Interests
                  _buildLabel('УВЛЕЧЕНИЯ'),
                  _buildChips(_allInterests, _interests),

                  // Appearance (gender-aware)
                  _buildLabel(_gender.isEmpty
                      ? 'ВНЕШНОСТЬ'
                      : 'ВНЕШНОСТЬ (${_gender == 'Мужской' ? 'МУЖ.' : 'ЖЕН.'})'),
                  _buildChips(_currentAppearanceOptions, _appearance),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(FilterData(
                    traits: _traits,
                    interests: _interests,
                    appearance: _appearance,
                    city: _cityController.text.trim(),
                    gender: _gender,
                    relationshipGoal: _relationshipGoal,
                    ageMin: _ageRange.start.round(),
                    ageMax: _ageRange.end.round(),
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  shadowColor: AppColors.primary.withOpacity(0.5),
                  elevation: 8,
                ),
                child: const Text('Применить',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
