import 'package:flutter/material.dart';
import '../../data/models/peat_profile.dart';

enum DnaBadgeSize { small, medium, large }

/// P.E.A.T DNA 배지 위젯
class DnaBadge extends StatelessWidget {
  final PeatProfile? peatProfile;
  final String? code;
  final DnaBadgeSize size;
  final bool showLabel;

  const DnaBadge({
    super.key,
    this.peatProfile,
    this.code,
    this.size = DnaBadgeSize.small,
    this.showLabel = false,
  }) : assert(peatProfile != null || code != null);

  @override
  Widget build(BuildContext context) {
    final typeCode = peatProfile?.typeCode ?? code!;
    
    double fontSize;
    EdgeInsets padding;

    switch (size) {
      case DnaBadgeSize.small:
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        break;
      case DnaBadgeSize.medium:
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
      case DnaBadgeSize.large:
        fontSize = 20;
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFF1D592)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            typeCode,
            style: TextStyle(
              color: const Color(0xFF121212),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: fontSize,
            ),
          ),
        ),
        if (showLabel && peatProfile != null) ...[
          const SizedBox(height: 8),
          Text(
            peatProfile!.typeName,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ],
    );
  }
}
