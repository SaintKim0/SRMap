import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/recent_viewed_provider.dart';
import '../widgets/location_card.dart';
import '../widgets/empty_state.dart';
import 'location_detail_screen.dart';
import '../widgets/fade_in_up.dart';

class RecentViewedListScreen extends StatefulWidget {
  const RecentViewedListScreen({super.key});

  @override
  State<RecentViewedListScreen> createState() => _RecentViewedListScreenState();
}

class _RecentViewedListScreenState extends State<RecentViewedListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<RecentViewedProvider>().loadRecentViewed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        centerTitle: true,
        title: const Text(
          '최근 본 맛집',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<RecentViewedProvider>(
            builder: (context, provider, child) {
              if (provider.recentLocations.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('전체 삭제'),
                      content: const Text('최근 본 맛집 목록을 모두 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.clearAllRecentViewed();
                            Navigator.pop(context);
                          },
                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('전체 삭제', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
      body: Consumer<RecentViewedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.recentLocations.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              message: '최근 본 맛집이 없습니다\n장소를 눌러 상세를 보면 여기에 쌓여요',
            );
          }

          final screenH = AppSpacing.screenPaddingHorizontal(context);
          return ListView.builder(
            padding: EdgeInsets.all(screenH),
            itemCount: provider.recentLocations.length,
            itemBuilder: (context, index) {
              final location = provider.recentLocations[index];
              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.spacingM(context)),
                  child: Stack(
                    children: [
                      LocationCard(
                        location: location,
                        isHorizontal: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationDetailScreen(
                                locationId: location.id,
                                previewLocation: location,
                              ),
                            ),
                          ).then((_) {
                            provider.loadRecentViewed();
                          });
                        },
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                          onPressed: () {
                            provider.removeRecentViewed(location.id);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
