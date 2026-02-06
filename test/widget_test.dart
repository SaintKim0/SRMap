// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_map/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title or main screen content is present.
    // Note: 'SceneMap' might be in the AppBar which is part of MainScreen
    // But we need to pump enough frames for async initialization if any.
    // However, MainScreen is synchronous.
    
    // Verify BottomNavigationBar items are present
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('지도'), findsOneWidget);
    expect(find.text('검색'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
  });
}
