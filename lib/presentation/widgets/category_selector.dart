import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';

class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories = const [
    '한식',
    '중식',
    '일식',
    '양식',
    '카페/디저트',
    '분식',
    '아시안',
    '패스트푸드',
    '기타',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingHorizontal(context),
        vertical: 8,
      ),
      child: Row(
        children: [
          _buildChip(context, '전체', selectedCategory == null, () => onCategorySelected(null)),
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _buildChip(
              context, 
              category, 
              selectedCategory == category, 
              () => onCategorySelected(category)
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onPressed: onTap,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
