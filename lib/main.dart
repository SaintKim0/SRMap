import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/location_provider.dart';
import 'presentation/providers/bookmark_provider.dart';
import 'presentation/providers/visited_provider.dart';
import 'presentation/providers/recent_viewed_provider.dart';
import 'presentation/providers/location_provider_service.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/my_page_screen.dart';
import 'data/services/preferences_service.dart';
import 'data/services/map_service.dart';
import 'data/services/nearby_notification_service.dart';
import 'presentation/providers/bottom_navigation_provider.dart';
import 'presentation/providers/user_profile_provider.dart';
import 'presentation/providers/peat_profile_provider.dart';
import 'presentation/providers/food_preference_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize preferences
  await PreferencesService.instance.init();
  
  // Initialize Naver Map SDK
  await MapService.instance.initialize();

  // Initialize Environment Variables
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationDataProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => VisitedProvider()),
        ChangeNotifierProvider(create: (_) => RecentViewedProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider(PreferencesService.instance)),
        ChangeNotifierProvider(create: (_) => PeatProfileProvider(PreferencesService.instance)),
        ChangeNotifierProvider(create: (_) => FoodPreferenceProvider(PreferencesService.instance)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(PreferencesService.instance)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TasteMap',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize location data once on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. 위치 정보 가져오기 시작 (권한 요청 포함)
      final locProvider = Provider.of<LocationProvider>(context, listen: false);
      locProvider.getCurrentLocation();

      // 2. 데이터 로드
      final dataProvider = Provider.of<LocationDataProvider>(context, listen: false);
      await dataProvider.initialize();

      // 3. 근처 맛집 알림 체크 (데이터 로드 완료 후)
      if (mounted) {
        NearbyNotificationService.instance.checkAndNotify(
          context,
          allLocations: dataProvider.allLocations,
          onTapShowOnMap: () {
            // 알림 보고 지도 탭 시 동작
            Provider.of<BottomNavigationProvider>(context, listen: false).setIndex(1); // 지도 탭으로 이동
            locProvider.requestPermission(); // 권한 보장
            dataProvider.requestMoveToMyLocationOnce(); // 내 위치로 이동 요청
          },
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NearbyNotificationService.requestCheckOnNextBuild = true;
      if (mounted) setState(() {});
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const SearchScreen(),
    const MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BottomNavigationProvider>(
        builder: (context, provider, child) => _screens[provider.currentIndex],
      ),
      bottomNavigationBar: Consumer<BottomNavigationProvider>(
        builder: (context, provider, child) => BottomNavigationBar(
          currentIndex: provider.currentIndex,
          onTap: (index) {
            if (index == 0) {
              // Always clear filters and switch to home when Home button is pressed
              context.read<LocationDataProvider>().clearSectorFilter();
              provider.setIndex(0);
            } else {
              provider.setIndex(index);
            }
          },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    ),
    );
  }
}
