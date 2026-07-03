import 'package:flutter/material.dart';
import '../theme.dart';

class SelectableChips extends StatefulWidget {
  final List<String> items;
  final List<String> selected;
  final Function(List<String>) onChanged;

  const SelectableChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<SelectableChips> createState() => _SelectableChipsState();
}

class _SelectableChipsState extends State<SelectableChips> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  @override
  void didUpdateWidget(SelectableChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _selected = _selected.where((s) => widget.items.contains(s)).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(_selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.items.map((item) {
        final isSelected = _selected.contains(item);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(item);
              } else {
                _selected.add(item);
              }
              widget.onChanged(_selected);
            });
          },
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
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
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
}