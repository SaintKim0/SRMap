import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/location_card.dart';
import '../widgets/empty_state.dart';
import 'location_detail_screen.dart';
import '../widgets/fade_in_up.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh bookmarks when entering screen
    context.read<BookmarkProvider>().loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('저장한 맛집'),
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.bookmarkedLocations.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border,
              message: '저장한 맛집이 없습니다',
            );
          }

          final screenH = AppSpacing.screenPaddingHorizontal(context);
          return ListView.builder(
            padding: EdgeInsets.all(screenH),
            itemCount: provider.bookmarkedLocations.length,
            itemBuilder: (context, index) {
              final location = provider.bookmarkedLocations[index];
              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.spacingM(context)),
                  child: LocationCard(
                    location: provider.bookmarkedLocations[index],
                    isHorizontal: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationDetailScreen(
                            locationId: provider.bookmarkedLocations[index].id,
                            previewLocation: provider.bookmarkedLocations[index],
                          ),
                        ),
                      ).then((_) {
                        // Refresh validation when returning
                        provider.loadBookmarks();
                      });
                    },
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
