import 'package:flutter/material.dart';
import '../widgets/program_thumbnail.dart';

class ProgramThumbnailDemoScreen extends StatelessWidget {
  const ProgramThumbnailDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> programs = [
      '맛있는 녀석들',
      '1박 2일 시즌4',
      '수요미식회',
      '나 혼자 산다',
      '전지적 참견시점',
      '골목식당',
      '런닝맨',
      '식객 허영만의 백반기행',
      '전현무계획',
      '무한도전'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로그램 썸네일 시안'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: programs.length,
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProgramThumbnail(
                      programName: programs[index],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  programs[index],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
