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
    
    // Clean program name for display
    String displayName = programName;
    if (displayName.contains('시즌')) {
      // Handle seasons if needed, or keep as is
    }

    return Container(
      width: width,
      height: height,
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
            right: -height * 0.2,
            bottom: -height * 0.2,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.play_circle_outline,
                size: height * 0.8,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: -height * 0.1,
            top: -height * 0.1,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.tv,
                size: height * 0.4,
                color: Colors.white,
              ),
            ),
          ),
          
          // Main Text
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stylized Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ENTERTAINMENT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: height * 0.08,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  // Program Title
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: height * (displayName.length > 10 ? 0.15 : 0.18),
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Decorative underline
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
