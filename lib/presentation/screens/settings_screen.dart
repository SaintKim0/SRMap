import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/nearby_notification_service.dart';
import '../providers/bottom_navigation_provider.dart';
import '../providers/location_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService.instance;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final enabled = _prefs.nearbyNotificationEnabled;
    final radiusM = _prefs.notificationRadiusMeters;
    final radiusText = radiusM >= 1000
        ? '${(radiusM / 1000).toStringAsFixed(1)}km'
        : '${radiusM}m';

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, '알림'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('근처 맛집 알림'),
            subtitle: const Text('반경 내 맛집이 있으면 알림'),
            value: enabled,
            onChanged: (value) async {
              await _prefs.setNearbyNotificationEnabled(value);
              _refresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('알림 반경'),
            subtitle: Text(radiusText),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRadiusPicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 다시보기'),
            subtitle: const Text('놓친 알림이 있으면 다시 확인'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _onAlarmRecheck(context),
          ),
          const Divider(),
          _buildSectionHeader(context, '앱 설정'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('테마 설정'),
            subtitle: Consumer<ThemeProvider>(
              builder: (context, provider, child) {
                switch (provider.themeMode) {
                  case ThemeMode.system:
                    return const Text('시스템 기본값');
                  case ThemeMode.light:
                    return const Text('라이트 모드');
                  case ThemeMode.dark:
                    return const Text('다크 모드');
                }
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context),
          ),
          const Divider(),
          _buildSectionHeader(context, '정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 버전'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader(context, '문의'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('문의하기'),
            subtitle: const Text('support@scenemap.com'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Future<void> _onAlarmRecheck(BuildContext context) async {
    final locationProvider = context.read<LocationDataProvider>();
    if (locationProvider.allLocations.isEmpty) {
      await locationProvider.loadAllLocations();
    }
    if (!context.mounted) return;
    await NearbyNotificationService.instance.checkAndNotify(
      context,
      allLocations: locationProvider.allLocations,
      forceShow: true,
      showEmptyMessage: true,
      onTapShowOnMap: () {
        if (context.mounted) {
          context.read<LocationDataProvider>().requestMoveToMyLocationOnce();
          context.read<BottomNavigationProvider>().setIndex(1);
        }
      },
    );
  }

  Future<void> _showRadiusPicker(BuildContext context) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 반경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PreferencesService.notificationRadiusOptions.map((m) {
            final text = m >= 1000 ? '${m ~/ 1000}km' : '${m}m';
            return ListTile(
              title: Text(text),
              onTap: () => Navigator.pop(context, m),
            );
          }).toList(),
        ),
      ),
    );
    if (chosen != null && context.mounted) {
      await _prefs.setNotificationRadiusMeters(chosen);
      _refresh();
    }
  }

  Future<void> _showThemePicker(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();
    final currentTheme = themeProvider.themeMode;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('시스템 설정 따름'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('라이트 모드'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('다크 모드'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingHorizontal(context),
        vertical: AppSpacing.spacingS(context),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
