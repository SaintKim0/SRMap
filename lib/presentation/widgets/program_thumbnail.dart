import 'package:flutter/material.dart';

class ProgramThumbnail extends StatelessWidget {
  final String programName;
  final double width;
  final double height;
  final bool isHorizontal;

  const ProgramThumbnail({
    super.key,
    required this.programName,
    this.width = 160,
    this.height = 90,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a consistent color based on the program name
    final int hash = programName.hashCode;
    final List<List<Color>> gradients = [
      [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)], // Purple
      [const Color(0xFFB71C1C), const Color(0xFFD32F2F)], // Red
      [const Color(0xFF0D47A1), const Color(0xFF1976D2)], // Blue
      [const Color(0xFF1B5E20), const Color(0xFF388E3C)], // Green
      [const Color(0xFFE65100), const Color(0xFFF57C00)], // Orange
      [const Color(0xFF006064), const Color(0xFF0097A7)], // Cyan
      [const Color(0xFF311B92), const Color(0xFF512DA8)], // Deep Purple
      [const Color(0xFF1A237E), const Color(0xFF303F9F)], // Indigo
      [const Color(0xFF880E4F), const Color(0xFFC2185B)], // Pink
      [const Color(0xFF4A148C), const Color(0xFF7B1FA2)], // Purple Accent
    ];
    
    final List<Color> gradient = gradients[hash.abs() % gradients.length];
    
    // 3. semantic line breaks for common programs
    String formattedName = programName;
    final Map<String, String> semanticBreaks = {
      '생생정보통': '생생\n정보통',
      '2TV생생정보': '2TV\n생생정보',
      '식객허영만의백반기행': '식객 허영만의\n백반기행',
      '식객 허영만의 백반기행': '식객 허영만의\n백반기행',
      '생활의달인': '생활의\n달인',
      '생활의 달인': '생활의\n달인',
      '맛있는녀석들': '맛있는\n녀석들',
      '맛있는 녀석들': '맛있는\n녀석들',
      '백종원의3대천왕': '백종원의\n3대천왕',
      '백종원의 3대천왕': '백종원의\n3대천왕',
      '전지적참견시점': '전지적\n참견시점',
      '전지적 참견시점': '전지적\n참견시점',
      '백종원의골목식당': '백종원의\n골목식당',
      '백종원의 골목식당': '백종원의\n골목식당',
      '수요미식회': '수요\n미식회',
      '놀라운토요일': '놀라운\n토요일',
      '놀라운 토요일': '놀라운\n토요일',
      '전현무계획3': '전현무\n계획3',
      '전현무계획2': '전현무\n계획2',
      '전현무계획': '전현무\n계획',
      '생방송오늘저녁': '생방송\n오늘저녁',
      '모닝와이드': '모닝\n와이드',
      '맛있을지도': '맛있을\n지도',
      '생방송투데이': '생방송\n투데이',
      'VJ특공대': 'VJ\n특공대',
      '성시경의 먹을텐데': '성시경의\n먹을텐데',
      '6시 내고향': '6시\n내고향',
    };

    if (semanticBreaks.containsKey(formattedName)) {
      formattedName = semanticBreaks[formattedName]!;
    } else if (formattedName.length > 7 && !formattedName.contains('\n')) {
      // Default break for long names if not in map (e.g., at space)
      if (formattedName.contains(' ')) {
        final parts = formattedName.split(' ');
        if (parts.length >= 2) {
          formattedName = '${parts[0]}\n${parts.sublist(1).join(' ')}';
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final actualWidth = constraints.maxWidth == double.infinity ? width : constraints.maxWidth;
        final actualHeight = constraints.maxHeight == double.infinity ? height : constraints.maxHeight;

        return Container(
          width: actualWidth,
          height: actualHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Decorative Elements
              Positioned(
                right: -actualHeight * 0.2,
                bottom: -actualHeight * 0.2,
                child: Opacity(
                  opacity: 0.15,
                  child: Icon(
                    Icons.live_tv,
                    size: actualHeight * 0.7,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Main Text
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stylized Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SHOW',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: actualHeight * 0.06, // Smaller
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Program Title
                      Text(
                        formattedName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: actualHeight * 0.11, // Standardized to smaller size for consistency
                          fontWeight: FontWeight.w900,
                          height: 1.1, // Tighter line height
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
