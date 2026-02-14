
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

  // Steps: 전체, 100km, 50km, 25km, 10km, 5km, 내 위치(1km)
  static const List<double?> _steps = [null, 100.0, 50.0, 25.0, 10.0, 5.0, 1.0];

  @override
  Widget build(BuildContext context) {
    // Determine current slider value based on selectedDistance
    double currentSliderValue = 0.0;
    if (selectedDistance != null) {
      final index = _steps.indexOf(selectedDistance);
      if (index != -1) {
        currentSliderValue = index.toDouble();
      }
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
                style: const TextStyle(color: Colors.white, fontSize: 12),
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
            children: _steps.map((dist) {
              String label;
              if (dist == null) {
                label = '전체';
              } else if (dist == 1.0) {
                label = '내 위치';
              } else {
                label = '${dist.round()}km';
              }
              return Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
