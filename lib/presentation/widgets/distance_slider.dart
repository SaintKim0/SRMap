
import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';

class DistanceSlider extends StatelessWidget {
  final double? selectedDistance;
  final Function(double?) onDistanceSelected;
  final int totalCount;

  const DistanceSlider({
    super.key,
    required this.selectedDistance,
    required this.onDistanceSelected,
    this.totalCount = 0,
  });

  // Steps matching user request: Left=All, First=100km ... Right=My Location(0km/1km)
  static const List<double?> _steps = [null, 100.0, 50.0, 25.0, 10.0, 5.0, 1.0];

  @override
  Widget build(BuildContext context) {
    // Determine current slider value based on selectedDistance
    // If selected is not in steps, find closest or default to 0 (All)
    double currentSliderValue = 0.0;
    if (selectedDistance == null) {
      currentSliderValue = 0.0;
    } else {
      final index = _steps.indexOf(selectedDistance);
      if (index != -1) {
        currentSliderValue = index.toDouble();
      } else {
        // Fallback for custom values if any (though we stick to steps)
        currentSliderValue = 0.0; 
      }
    }

    String rightLabelText;
    if (selectedDistance == null) {
      rightLabelText = '전체 지역';
    } else if (selectedDistance == 1.0) {
      rightLabelText = '내 위치 (1km)';
    } else {
      rightLabelText = '${selectedDistance!.round()}km 이내';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '전국($totalCount)', 
                style: const TextStyle(color: Colors.white70, fontSize: 12)
              ),
              Text(
                rightLabelText,
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 14
                ),
              ),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            // Custom Ticks
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_steps.length, (index) {
                  return Container(
                    width: 1,
                    height: 8,
                    color: Colors.white54,
                  );
                }),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                trackHeight: 2.0,
                tickMarkShape: SliderTickMarkShape.noTickMark,
                // Make thumb slightly bigger for easier touch
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              ),
              child: Slider(
                value: currentSliderValue,
                min: 0.0,
                max: (_steps.length - 1).toDouble(),
                divisions: _steps.length - 1,
                onChanged: (val) {
                  final index = val.round();
                  onDistanceSelected(_steps[index]);
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('전체', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('100km', style: TextStyle(color: Colors.white38, fontSize: 10)),     // 2nd tick
              Spacer(),
              Text('내 위치', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
