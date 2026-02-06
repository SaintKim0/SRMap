import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/peat_profile_provider.dart';
import 'peat_result_screen.dart';

/// P.E.A.T v2.0 미식 DNA 테스트 설문 화면 (Spectrum)
class PeatSurveyScreen extends StatefulWidget {
  const PeatSurveyScreen({super.key});

  @override
  State<PeatSurveyScreen> createState() => _PeatSurveyScreenState();
}

class _PeatSurveyScreenState extends State<PeatSurveyScreen> {
  int _currentStep = 0;
  final Map<String, double> _scores = {
    'P': 0,
    'E': 0,
    'A': 0,
    'T': 0,
  };

  // 현재 선택된 값 (초기값: 중립 0.0)
  double _currentValue = 0.0;

  // 설문 데이터 (양극단 정의)
  final List<Map<String, dynamic>> _questions = [
    {
      'dimension': 'P',
      'question': '기념일 저녁, 당신의 선택은?',
      'optionA': {
        'text': '가격 상관없이\n최고급 다이닝',
        'img': 'assets/images/survey/premium_dining.jpg',
      },
      'optionB': {
        'text': '합리적인 가격의\n빕 구르망',
        'img': 'assets/images/survey/budget_restaurant.jpg',
      },
    },
    {
      'dimension': 'E',
      'question': '선호하는 식당의 분위기는?',
      'optionA': {
        'text': '고요하고\n프라이빗한 공간',
        'img': 'assets/images/survey/calm_space.jpg',
      },
      'optionB': {
        'text': '활기차고\n시끌벅적한 노포',
        'img': 'assets/images/survey/vivid_market.jpg',
      },
    },
    {
      'dimension': 'A',
      'question': '맛집을 고르는 기준은?',
      'optionA': {
        'text': '미슐랭 등\n전문가의 검증',
        'img': 'assets/images/survey/michelin_star.jpg',
      },
      'optionB': {
        'text': 'TV 예능이나\nSNS 핫플',
        'img': 'assets/images/survey/tv_show.jpg',
      },
    },
    {
      'dimension': 'T',
      'question': '오늘 끌리는 요리 스타일은?',
      'optionA': {
        'text': '전통을 지킨\n원조의 맛',
        'img': 'assets/images/survey/traditional_food.jpg',
      },
      'optionB': {
        'text': '셰프의 창의적인\n퓨전 요리',
        'img': 'assets/images/survey/fusion_food.jpg',
      },
    },
  ];

  void _nextStep() {
    setState(() {
      final dimension = _questions[_currentStep]['dimension'] as String;
      // Slider Logic: Right(1.0) is B(Negative), Left(-1.0) is A(Positive)
      // So score should be reversed to match A=Positive logic
      _scores[dimension] = -_currentValue;

      if (_currentStep < _questions.length - 1) {
        _currentStep++;
        _currentValue = 0.0; // 다음 질문은 중립에서 시작
      } else {
        _completesurvey();
      }
    });
  }

  Future<void> _completesurvey() async {
    final provider = context.read<PeatProfileProvider>();

    final success = await provider.createProfileFromSurvey(
      priceScore: _scores['P']!,
      energyScore: _scores['E']!,
      authorityScore: _scores['A']!,
      tasteScore: _scores['T']!,
    );

    if (!mounted) return;

    if (success && provider.profile != null) {
      // 결과 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PeatResultScreen(profile: provider.profile!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필 저장에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentStep];
    final optionA = question['optionA'] as Map<String, dynamic>;
    final optionB = question['optionB'] as Map<String, dynamic>;
    final progress = (_currentStep + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '질문 ${_currentStep + 1} / ${_questions.length}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 진행률 표시
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1E1E1E),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 4,
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 질문
                    Text(
                      question['question'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 옵션 A & B 가로 배치
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildOptionPreview(
                              optionA['text'],
                              optionA['img'],
                              // Left Area: Active if value < 0 (Since Left is -1.0)
                              isActive: _currentValue < 0,
                              isOptionA: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildOptionPreview(
                              optionB['text'],
                              optionB['img'],
                              // Right Area: Active if value > 0 (Since Right is 1.0)
                              isActive: _currentValue > 0,
                              isOptionA: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 스펙트럼 슬라이더
                    _buildSpectrumSlider(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 다음 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep < _questions.length - 1 ? '다음' : '결과 보기',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionPreview(String title, String imageAsset, {
    required bool isActive,
    required bool isOptionA,
  }) {
    // 활성 상태에 따른 투명도 및 테두리
    final opacity = isActive ? 1.0 : 0.4;
    final borderColor = isActive 
        ? Theme.of(context).colorScheme.secondary 
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        setState(() {
          // Tap A (Left) -> -1.0
          // Tap B (Right) -> 1.0
          _currentValue = isOptionA ? -1.0 : 1.0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(imageAsset),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16, // 가로 레이아웃이므로 폰트 살짝 작게
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpectrumSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('A', style: TextStyle(color: Colors.white54)),
            Text('중립', style: TextStyle(color: Colors.white54)),
            Text('B', style: TextStyle(color: Colors.white54)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            valueIndicatorColor: Theme.of(context).primaryColor,
            trackHeight: 6.0,
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
          ),
          child: Slider(
            value: _currentValue,
            min: -1.0,
            max: 1.0,
            divisions: 4, // 5단계 ( -1.0, -0.5, 0.0, 0.5, 1.0 )
            label: _getLabel(_currentValue),
            onChanged: (value) {
              setState(() {
                _currentValue = value;
              });
            },
          ),
        ),
        Text(
          _getLabel(_currentValue),
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _getLabel(double value) {
    // Left (-1.0) is A, Right (1.0) is B
    if (value <= -0.8) return '매우 A 선호';
    if (value <= -0.3) return '약간 A 선호';
    if (value >= 0.8) return '매우 B 선호';
    if (value >= 0.3) return '약간 B 선호';
    return '중립 / 상관없음';
  }
}
