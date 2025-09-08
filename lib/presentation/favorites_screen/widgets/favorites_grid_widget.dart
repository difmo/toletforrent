import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FavoritesGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> properties;
  final Function(Map<String, dynamic>) onPropertyTap;
  final Function(Map<String, dynamic>) onFavoriteTap;
  final Function(Map<String, dynamic>) onShareTap;
  final Function(Map<String, dynamic>) onContactTap;

  const FavoritesGridWidget({
    super.key,
    required this.properties,
    required this.onPropertyTap,
    required this.onFavoriteTap,
    required this.onShareTap,
    required this.onContactTap,
  });

  @override
Widget build(BuildContext context) {
  final isWide = 100.w > 600;
  final crossAxisCount = isWide ? 3 : 2;

  // spacing/padding
  final horizontalPad = 4.w;
  final crossGap = 3.w;
  final mainGap = 2.h;

  // compute tile size
  final tileWidth =
      (100.w - horizontalPad * 2 - crossGap * (crossAxisCount - 1)) /
          crossAxisCount;
  final tileHeight = isWide ? tileWidth * 1.50 : tileWidth * 1.55;

  return GridView.builder(
    padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 2.h),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossGap,
      mainAxisSpacing: mainGap,
      mainAxisExtent: tileHeight, // <-- critical so the card has enough height
    ),
    itemCount: properties.length,
    itemBuilder: (context, index) {
      return _PropertyCard(
        property: properties[index],
        onTap: () => onPropertyTap(properties[index]),
        onFavoriteTap: () => onFavoriteTap(properties[index]),
        onShareTap: () => onShareTap(properties[index]),
        onContactTap: () => onContactTap(properties[index]),
        onLongPress: () => _showQuickActions(context, properties[index]),
      );
    },
  );
}


  void _showQuickActions(BuildContext context, Map<String, dynamic> property) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite_border',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              title: Text('Remove from Favorites',
                  style: AppTheme.lightTheme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onFavoriteTap(property);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              title: Text('Share Property',
                  style: AppTheme.lightTheme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onShareTap(property);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'chat',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 24,
              ),
              title: Text('Contact Owner',
                  style: AppTheme.lightTheme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onContactTap(property);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onShareTap;
  final VoidCallback onContactTap;
  final VoidCallback onLongPress;

  const _PropertyCard({
    required this.property,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onShareTap,
    required this.onContactTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Safe location + distance
    final String location = ((property['location'] ??
            property['locationText'] ??
            property['address'] ??
            '') as String)
        .trim();
    final String distance = (property['distance']?.toString() ?? '').trim();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // ---- Image header (predictable height) ----
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CustomImageWidget(
                      imageUrl: property['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface
                              .withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightTheme.shadowColor
                                  .withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 18,
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TO-LET',
                        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  if (property['isVerified'] == true)
                    Positioned(
                      bottom: 2.w,
                      right: 2.w,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 12,
                                color:
                                    AppTheme.lightTheme.colorScheme.onSecondary),
                            SizedBox(width: 1.w),
                            Text(
                              'Verified',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---- Details + actions (compact) ----
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // compact
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top texts
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (property['price'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                        if (location.isNotEmpty || distance.isNotEmpty) ...[
                          SizedBox(height: 0.6.h),
                          Row(
                            children: [
                              if (location.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              if (location.isNotEmpty && distance.isNotEmpty)
                                SizedBox(width: 1.w),
                              if (distance.isNotEmpty)
                                Text(
                                  distance,
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        SizedBox(height: 0.6.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (property['bhk'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme
                                    .lightTheme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                '• ${(property['type'] ?? '').toString()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme
                                    .lightTheme.textTheme.labelMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onShareTap,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(vertical: 1.w),
                              side: BorderSide(
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'share',
                                  size: 14,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  'Share',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onContactTap,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(vertical: 1.w),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'phone',
                                  size: 14,
                                  color: AppTheme
                                      .lightTheme.colorScheme.onPrimary,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  'Call',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
