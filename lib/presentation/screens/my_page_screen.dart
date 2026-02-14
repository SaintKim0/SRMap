import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/bookmark_provider.dart';
import '../providers/visited_provider.dart';
import '../providers/peat_profile_provider.dart';
import '../providers/user_profile_provider.dart';
import 'package:screen_map/presentation/providers/food_preference_provider.dart';
import '../widgets/dna_badge.dart';
import 'bookmark_list_screen.dart';
import 'visited_list_screen.dart';
import 'recent_viewed_list_screen.dart';
import 'settings_screen.dart';
import 'peat_survey_screen.dart';
import 'food_preference_survey_screen.dart';
import 'profile_edit_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().loadBookmarks();
      context.read<VisitedProvider>().loadVisited();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        centerTitle: true,
        title: const Text(
          '마이 페이지',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingHorizontal(context),
          vertical: AppSpacing.spacingM(context),
        ),
        child: Column(
          children: [
            _buildProfileSection(),
            SizedBox(height: AppSpacing.spacingL(context)),
            _buildStatsSection(),
            SizedBox(height: AppSpacing.spacingM(context)),
            _buildThisMonthAndBadgesSection(),
            SizedBox(height: AppSpacing.spacingL(context)),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final avatarR = AppSpacing.avatarRadius(context);
    return Consumer3<UserProfileProvider, PeatProfileProvider, FoodPreferenceProvider>(
      builder: (context, userProvider, peatProvider, foodProvider, child) {
        final user = userProvider.userProfile;
        final peatProfile = peatProvider.profile;
        final hasPeat = peatProvider.hasProfile;

        return Column(
          children: [
            CircleAvatar(
              radius: avatarR,
              backgroundImage: user.profileImage != null 
                  ? AssetImage(user.profileImage!) 
                  : const AssetImage('assets/images/user_placeholder.png'),
              backgroundColor: Colors.grey,
              child: user.profileImage == null 
                  ? Icon(Icons.person, size: avatarR, color: Colors.white)
                  : null,
            ),
            SizedBox(height: AppSpacing.spacingM(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.nickname ?? '맛 탐험가',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                SizedBox(width: AppSpacing.spacingS(context)),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (hasPeat && peatProfile != null) ...[
              SizedBox(height: AppSpacing.spacingS(context)),
              // Display DNA Badge if available
              DnaBadge(
                peatProfile: peatProfile, 
                size: DnaBadgeSize.medium,
                showLabel: true,
              ),
            ] else ...[
              SizedBox(height: AppSpacing.spacingS(context)),
              if (foodProvider.hasPreference) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    foodProvider.preference?.characterType ?? '미식가',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  user.statusMessage ?? '나만의 맛 지도를 만들어보세요!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ],
          ],
        );
      }
    );
  }

  Widget _buildStatsSection() {
    return Consumer2<BookmarkProvider, VisitedProvider>(
      builder: (context, bookmarkProvider, visitedProvider, child) {
        final cardP = AppSpacing.getCardPadding(context);
        final radius = AppSpacing.cardRadius(context);
        return Container(
          padding: EdgeInsets.symmetric(vertical: cardP.top),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(context, '저장', '${bookmarkProvider.bookmarkedLocations.length}'),
              _buildVerticalDivider(),
              _buildStatItem(context, '방문', '${visitedProvider.visitedCount}'),
              _buildVerticalDivider(),
              _buildStatItem(context, '리뷰', '0'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: AppSpacing.spacingXS(context)),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildThisMonthAndBadgesSection() {
    return Consumer<VisitedProvider>(
      builder: (context, provider, child) {
        final thisMonth = provider.visitedThisMonthCount;
        final badges = provider.achievedBadges;
        if (thisMonth == 0 && badges.isEmpty) return const SizedBox.shrink();
        final cardP = AppSpacing.getCardPadding(context);
        final radius = AppSpacing.cardRadius(context);
        final iconM = AppSpacing.iconSizeM(context);
        final spacingSVal = AppSpacing.spacingS(context);
        return Container(
          width: double.infinity,
          padding: cardP,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thisMonth > 0) ...[
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: iconM, color: Theme.of(context).primaryColor),
                    SizedBox(width: spacingSVal),
                    Text(
                      '이번 달 $thisMonth곳 방문',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                if (badges.isNotEmpty) SizedBox(height: AppSpacing.spacingM(context)),
              ],
              if (badges.isNotEmpty) ...[
                Text(
                  '달성 뱃지',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: spacingSVal),
                Wrap(
                  spacing: spacingSVal,
                  runSpacing: AppSpacing.spacingXS(context),
                  children: badges.map((label) {
                    return Chip(
                      label: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                      padding: AppSpacing.getTextButtonPadding(context),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.bookmark,
          title: '저장한 맛집',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookmarkListScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.check_circle_outline,
          title: '다녀온 곳',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VisitedListScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.history,
          title: '최근 본 맛집',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecentViewedListScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.rate_review,
          title: '나의 리뷰',
          onTap: () {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('준비 중인 기능입니다.')),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.science,
          title: '미식 DNA 분석',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeatSurveyScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.restaurant_menu,
          title: '음식 취향 설정',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FoodPreferenceSurveyScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final radius = AppSpacing.cardRadius(context);
    final spacingSVal = AppSpacing.spacingS(context);
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingM(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white12 
              : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(spacingSVal),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: AppSpacing.iconSizeM(context)),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.chevron_right, 
          color: Theme.of(context).iconTheme.color?.withOpacity(0.5) ?? Colors.grey[400],
          size: AppSpacing.iconSizeM(context)
        ),
        onTap: onTap,
      ),
    );
  }
}
