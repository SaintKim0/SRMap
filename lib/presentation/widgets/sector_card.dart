import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';

class SectorCard extends StatelessWidget {
  final String sectorTitle;
  final String sectorIcon;
  final String mediaType;
  final List<String> contentTitles;
  final VoidCallback? onSeeAll;
  final Function(String) onContentTap;

  const SectorCard({
    Key? key,
    required this.sectorTitle,
    required this.sectorIcon,
    required this.mediaType,
    required this.contentTitles,
    this.onSeeAll,
    required this.onContentTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconL = AppSpacing.iconSizeL(context);
    final spacingSVal = AppSpacing.spacingS(context);
    final chipH = AppSpacing.chipRowHeight(context);
    final captionSize = AppSpacing.captionFontSize(context);
    return Container(
      margin: AppSpacing.getCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: AppSpacing.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      sectorIcon,
                      style: TextStyle(fontSize: iconL),
                    ),
                    SizedBox(width: spacingSVal),
                    Text(
                      sectorTitle,
                      style: TextStyle(
                        fontSize: iconL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onSeeAll != null)
                  InkWell(
                    onTap: onSeeAll,
                    child: Row(
                      children: [
                        Text(
                          '전체보기',
                          style: TextStyle(
                            fontSize: captionSize + 2,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: AppSpacing.spacingXS(context)),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: AppSpacing.iconSizeS(context),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: spacingSVal),
            const Divider(height: 1),
            SizedBox(height: spacingSVal),
            SizedBox(
              height: chipH,
              child: contentTitles.isEmpty
                  ? Center(
                      child: Text(
                        '콘텐츠가 없습니다',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: captionSize + 2,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: contentTitles.length,
                      itemBuilder: (context, index) {
                        final title = contentTitles[index];
                        return Padding(
                          padding: EdgeInsets.only(right: spacingSVal),
                          child: ActionChip(
                            label: Text(
                              title,
                              style: TextStyle(
                                fontSize: captionSize + 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () => onContentTap(title),
                            backgroundColor: Colors.grey[100],
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
