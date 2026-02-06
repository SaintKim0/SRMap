import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../providers/visited_provider.dart';
import '../widgets/location_card.dart';
import '../widgets/empty_state.dart';
import 'location_detail_screen.dart';
import '../widgets/fade_in_up.dart';

class VisitedListScreen extends StatefulWidget {
  const VisitedListScreen({super.key});

  @override
  State<VisitedListScreen> createState() => _VisitedListScreenState();
}

class _VisitedListScreenState extends State<VisitedListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<VisitedProvider>().loadVisited();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('다녀온 곳'),
      ),
      body: Consumer<VisitedProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.visitedLocations.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              message: '다녀온 곳이 없습니다\n장소 상세에서 "다녀온 곳 추가"를 눌러보세요',
            );
          }

          final screenH = AppSpacing.screenPaddingHorizontal(context);
          return ListView.builder(
            padding: EdgeInsets.all(screenH),
            itemCount: provider.visitedLocations.length,
            itemBuilder: (context, index) {
              final location = provider.visitedLocations[index];
              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.spacingM(context)),
                  child: LocationCard(
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
                        provider.loadVisited();
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
