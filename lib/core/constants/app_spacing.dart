import 'package:flutter/material.dart';

/// UI_UX_STYLE_GUIDE §6·§8 기준 반응형 수치.
/// 브레이크포인트: Small <360 / Medium 360~399 / Large ≥400 (화면 폭)
enum _Breakpoint { small, medium, large }

class AppSpacing {
  AppSpacing._();

  static _Breakpoint _breakpoint(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return _Breakpoint.small;
    if (w < 400) return _Breakpoint.medium;
    return _Breakpoint.large;
  }

  // ----- §8.1 패딩·여백 -----
  static double screenPaddingHorizontal(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 12;
      case _Breakpoint.medium:
      case _Breakpoint.large:
        return 16;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final h = screenPaddingHorizontal(context);
    return EdgeInsets.symmetric(horizontal: h);
  }

  static double cardPaddingValue(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 12;
      case _Breakpoint.medium:
        return 14;
      case _Breakpoint.large:
        return 16;
    }
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    final p = cardPaddingValue(context);
    return EdgeInsets.all(p);
  }

  static EdgeInsets getCardMargin(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case _Breakpoint.medium:
      case _Breakpoint.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  static EdgeInsets getButtonPadding(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return const EdgeInsets.symmetric(vertical: 8, horizontal: 12);
      case _Breakpoint.medium:
        return const EdgeInsets.symmetric(vertical: 10, horizontal: 16);
      case _Breakpoint.large:
        return const EdgeInsets.symmetric(vertical: 12, horizontal: 24);
    }
  }

  static EdgeInsets getTextButtonPadding(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 4);
      case _Breakpoint.medium:
      case _Breakpoint.large:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    }
  }

  // ----- §8.1 간격 -----
  static double spacingL(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 20;
      case _Breakpoint.medium:
      case _Breakpoint.large:
        return 24;
    }
  }

  static double spacingM(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 12;
      case _Breakpoint.medium:
      case _Breakpoint.large:
        return 16;
    }
  }

  static double spacingS(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
      case _Breakpoint.medium:
        return 8;
      case _Breakpoint.large:
        return 10;
    }
  }

  static double spacingXS(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
      case _Breakpoint.medium:
        return 4;
      case _Breakpoint.large:
        return 6;
    }
  }

  // ----- §8.2 카드 -----
  static double cardRadius(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 12;
      case _Breakpoint.medium:
        return 14;
      case _Breakpoint.large:
        return 16;
    }
  }

  static double chipRowHeight(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 36;
      case _Breakpoint.medium:
        return 38;
      case _Breakpoint.large:
        return 40;
    }
  }

  static double iconBoxSize(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 48;
      case _Breakpoint.medium:
        return 52;
      case _Breakpoint.large:
        return 56;
    }
  }

  static double iconBoxRadius(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 8;
      case _Breakpoint.medium:
      case _Breakpoint.large:
        return 10;
    }
  }

  // ----- §8.3 버튼 -----
  static double buttonMinHeight(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 32;
      case _Breakpoint.medium:
        return 34;
      case _Breakpoint.large:
        return 38;
    }
  }

  static double iconButtonMinSize(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 40;
      case _Breakpoint.medium:
        return 44;
      case _Breakpoint.large:
        return 48;
    }
  }

  static double buttonIconSize(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 18;
      case _Breakpoint.medium:
        return 20;
      case _Breakpoint.large:
        return 22;
    }
  }

  // ----- §8.4 아이콘 -----
  static double iconSizeL(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 20;
      case _Breakpoint.medium:
        return 22;
      case _Breakpoint.large:
        return 24;
    }
  }

  static double iconSizeM(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 12;
      case _Breakpoint.medium:
        return 13;
      case _Breakpoint.large:
        return 14;
    }
  }

  static double iconSizeS(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 10;
      case _Breakpoint.medium:
        return 11;
      case _Breakpoint.large:
        return 12;
    }
  }

  static double avatarRadius(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 44;
      case _Breakpoint.medium:
        return 48;
      case _Breakpoint.large:
        return 50;
    }
  }

  // ----- §8.5 기타 -----
  static double horizontalCardHeight(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 176;
      case _Breakpoint.medium:
        return 184;
      case _Breakpoint.large:
        return 192;
    }
  }

  static double bottomSheetPadding(BuildContext context) {
    switch (_breakpoint(context)) {
      case _Breakpoint.small:
        return 16;
      case _Breakpoint.medium:
        return 18;
      case _Breakpoint.large:
        return 20;
    }
  }

  // ----- §6 텍스트 반응형 (보조) -----
  static double titleFontSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return 13;
    if (w < 400) return 14;
    return 15;
  }

  static double sectionHeaderFontSize(BuildContext context) {
    return titleFontSize(context);
  }

  static double captionFontSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return 10;
    if (w < 400) return 11;
    return 12;
  }
}
