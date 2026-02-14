import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/food_preference_provider.dart';
import '../../core/constants/app_spacing.dart';

class FoodPreferenceSurveyScreen extends StatefulWidget {
  const FoodPreferenceSurveyScreen({super.key});

  @override
  State<FoodPreferenceSurveyScreen> createState() => _FoodPreferenceSurveyScreenState();
}

class _FoodPreferenceSurveyScreenState extends State<FoodPreferenceSurveyScreen> {
  // Data Options
  final List<String> _cuisineOptions = [
    '한식', '일식', '중식', '양식', '아시안', '분식', '야식/안주', '패스트푸드', '카페/디저트'
  ];

  final List<String> _ingredientOptions = [
    '없음', '오이', '고수', '당근', '가지', '생선(날것)', '곱창/대창', 
    '민트초코', '견과류', '갑각류', '느끼한 음식'
  ];

  // State
  List<String> _selectedCuisines = [];
  int _spicyLevel = 1;
  List<String> _selectedDislikes = [];
  
  // Custom added items
  List<String> _customCuisines = [];
  List<String> _customDislikes = [];

  @override
  void initState() {
    super.initState();
    // Load existing preferences if any
    final existing = context.read<FoodPreferenceProvider>().preference;
    if (existing != null) {
      _selectedCuisines = List.from(existing.preferredCuisines);
      _spicyLevel = existing.spicyLevel;
      _selectedDislikes = List.from(existing.dislikedIngredients);

      // Identify custom items
      for (final item in _selectedCuisines) {
        if (!_cuisineOptions.contains(item)) {
          _customCuisines.add(item);
        }
      }
      for (final item in _selectedDislikes) {
        if (!_ingredientOptions.contains(item)) {
          _customDislikes.add(item);
        }
      }
    }
  }

  void _savePreferences() async {
    final characterType = _generateTrait();
    
    final success = await context.read<FoodPreferenceProvider>().updatePreference(
      preferredCuisines: _selectedCuisines,
      spicyLevel: _spicyLevel,
      dislikedIngredients: _selectedDislikes,
      characterType: characterType,
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('분석 완료!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('당신의 입맛 특성은:'),
              const SizedBox(height: 8),
              Text(
                characterType,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        centerTitle: true,
        title: const Text(
          '음식 취향 설정',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: context.watch<FoodPreferenceProvider>().isLoading ? null : _savePreferences,
            child: const Text('저장'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('선호하는 음식 종류'),
            const SizedBox(height: 16),
            _buildGridChips(
              defaultOptions: _cuisineOptions,
              customOptions: _customCuisines,
              selectedList: _selectedCuisines,
              onAddCustom: (value) {
                setState(() {
                  _customCuisines.add(value);
                  _selectedCuisines.add(value);
                });
              },
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('맵기 선호도'),
            const SizedBox(height: 16),
            _buildSpicySlider(),

            const SizedBox(height: 32),
            _buildSectionTitle('기피하는 재료/음식'),
            const SizedBox(height: 4),
            Text(
              '못 먹거나 싫어하는 재료를 선택해주세요',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildGridChips(
              defaultOptions: _ingredientOptions,
              customOptions: _customDislikes,
              selectedList: _selectedDislikes,
               onAddCustom: (value) {
                setState(() {
                  _customDislikes.add(value);
                  _selectedDislikes.add(value);
                  // If adding something custom, make sure '없음' is removed
                  if (_selectedDislikes.contains('없음')) {
                    _selectedDislikes.remove('없음');
                  }
                });
              },
            ),

            const SizedBox(height: 48),
            // Selection Complete Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: context.watch<FoodPreferenceProvider>().isLoading ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '선택 완료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGridChips({
    required List<String> defaultOptions,
    required List<String> customOptions,
    required List<String> selectedList,
    required Function(String) onAddCustom,
  }) {
    // 가장 긴 텍스트 기준 + 고정 크기
    const double chipWidth = 105.0; 
    const double chipHeight = 40.0;
    
    // Combine lists
    final allOptions = [...defaultOptions, ...customOptions];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...allOptions.map((option) {
          final isSelected = selectedList.contains(option);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedList.remove(option);
                } else {
                  // Special logic for "없음"
                  if (option == '없음') {
                    selectedList.clear();
                    selectedList.add('없음');
                  } else {
                    // If others selected, remove "없음"
                    if (selectedList.contains('없음')) {
                      selectedList.remove('없음');
                    }
                    selectedList.add(option);
                  }
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: chipWidth,
              height: chipHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11.5, // Reduced font size (approx 80% of 14)
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }),
        // Add Button
        if (customOptions.length < 5)
          InkWell(
            onTap: () => _showAddDialog(onAddCustom),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: chipWidth,
              height: chipHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[400]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddDialog(Function(String) onConfirm) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('직접 입력'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '입력해주세요 (예: 닭발)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  onConfirm(text);
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpicySlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.grey[200],
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
            valueIndicatorColor: Theme.of(context).primaryColor,
            trackHeight: 6.0,
          ),
          child: Slider(
            value: _spicyLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _getSpicyLabel(_spicyLevel),
            onChanged: (value) {
              setState(() {
                _spicyLevel = value.toInt();
              });
            },
          ),
        ),
        Text(
          _getSpicyLabel(_spicyLevel),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _getSpicyLabel(int level) {
    switch (level) {
      case 1: return '1단계: 안매운맛 (진라면 순한맛)';
      case 2: return '2단계: 보통 (신라면)';
      case 3: return '3단계: 매운맛 (불닭볶음면)';
      case 4: return '4단계: 아주 매운맛 (엽떡 오리지널)';
      case 5: return '5단계: 지옥의 맛 (핵불닭)';
      default: return '';
    }
  }

  String _generateTrait() {
    String trait = "";
    
    // 1. Spicy Analysis
    if (_spicyLevel >= 4) {
      trait += "불타는 ";
    } else if (_spicyLevel == 1) {
      trait += "순수한 ";
    }
    
    // 2. Dislikes Analysis
    if (_selectedDislikes.contains('없음') || _selectedDislikes.isEmpty) {
      trait += "무던한 ";
    } else if (_selectedDislikes.length >= 3) {
      trait += "섬세한 ";
    } else if (_selectedDislikes.contains('민트초코')) {
      trait += "반민초파 ";
    } else if (_selectedDislikes.contains('고수') || _selectedDislikes.contains('오이')) {
      trait += "취향 확실한 ";
    }

    // 3. Cuisine Analysis
    if (_selectedCuisines.length >= 6) {
      trait += "전설의 올라운드 ";
    } else if (_selectedCuisines.length >= 3) {
      trait += "미식 탐험가 ";
    } else if (_selectedCuisines.length == 1) {
      trait += "${_selectedCuisines.first} 매니아 ";
    }

    if (trait.isEmpty) trait = "진지한 ";
    trait += "미식가";
    
    return trait;
  }
}
