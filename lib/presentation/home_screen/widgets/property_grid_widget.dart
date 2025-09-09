import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PropertyGridWidget extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  final Function(Map<String, dynamic>)? onPropertyTap;
  final Function(Map<String, dynamic>)? onFavoriteTap;
  final Function(Map<String, dynamic>)? onShareTap;
  final Function(Map<String, dynamic>)? onContactTap;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  /// When true, this widget renders as a **non-scrollable section**
  /// (to be placed inside a page-level SingleChildScrollView).
  /// When false, it scrolls by itself and can trigger onLoadMore.
  final bool embedded;

  const PropertyGridWidget({
    super.key,
    required this.properties,
    this.onPropertyTap,
    this.onFavoriteTap,
    this.onShareTap,
    this.onContactTap,
    this.onLoadMore,
    this.isLoading = false,
    this.embedded = false,
  });

  @override
  State<PropertyGridWidget> createState() => _PropertyGridWidgetState();
}

class _PropertyGridWidgetState extends State<PropertyGridWidget> {
  final ScrollController _scrollController = ScrollController();

  bool get _canSelfScroll => !widget.embedded;
  bool get _canLoadMore => _canSelfScroll && !widget.isLoading && widget.onLoadMore != null;

  @override
  void initState() {
    super.initState();
    if (_canSelfScroll) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(covariant PropertyGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If embedded flag changes, attach/detach listener appropriately
    if (oldWidget.embedded != widget.embedded) {
      _scrollController.removeListener(_onScroll);
      if (_canSelfScroll) {
        _scrollController.addListener(_onScroll);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_canLoadMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      widget.onLoadMore!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.properties.isEmpty && !widget.isLoading) {
      return _buildEmptyState();
    }

    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Text(
        'Properties Near You',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final grid = GridView.builder(
      controller: _canSelfScroll ? _scrollController : null,
      shrinkWrap: widget.embedded, // key for embedding
      physics: widget.embedded
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(),
        childAspectRatio: 0.75,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: widget.properties.length + (widget.isLoading ? 4 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.properties.length) return _buildSkeletonCard();
        final property = widget.properties[index];
        return _buildPropertyCard(property);
      },
    );

    // IMPORTANT:
    // - When embedded: no Expanded, since parent (page) scrolls.
    // - When not embedded: use Expanded so this widget owns scrolling.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (widget.embedded) grid else Expanded(child: grid),
      ],
    );
  }

  int _getCrossAxisCount() => (100.w > 600) ? 3 : 2;

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final price = property['price'] as String? ?? '';
    final location = property['location'] as String? ?? '';
    final bhk = property['bhk'] as String? ?? '';
    final type = property['type'] as String? ?? '';
    final imageUrl = property['image'] as String? ?? '';
    final availability = property['availability'] as String?;
    final isVerified = property['isVerified'] == true;
    final isFavorite = property['isFavorite'] == true;
    final distance = property['distance']?.toString();

    return GestureDetector(
      onTap: () => widget.onPropertyTap?.call(property),
      onLongPress: () => _showQuickActions(property),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CustomImageWidget(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 1.h,
                    left: 2.w,
                    right: 2.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isVerified)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'VERIFIED',
                              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 8.sp,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => widget.onFavoriteTap?.call(property),
                          child: Container(
                            padding: EdgeInsets.all(0.8.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: CustomIconWidget(
                              iconName: isFavorite ? 'favorite' : 'favorite_border',
                              color: isFavorite
                                  ? Colors.red
                                  : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (availability != null && availability.isNotEmpty)
                    Positioned(
                      bottom: 1.h,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: availability == 'Available'
                              ? AppTheme.lightTheme.colorScheme.secondary
                              : AppTheme.warningLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          availability,
                          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 12,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Text(
                          bhk,
                          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(width: 1, height: 12, color: AppTheme.lightTheme.dividerColor),
                        SizedBox(width: 2.w),
                        Text(
                          type,
                          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (distance != null && distance.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        '$distance away',
                        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    width: 30.w,
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    width: 15.w,
                    height: 1.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'home_work',
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 80,
          ),
          SizedBox(height: 3.h),
          Text(
            'No Properties Found',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your filters or search in a different area',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/property-search-screen'),
            child: const Text('Adjust Filters'),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(Map<String, dynamic> property) {
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
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Text(
                    (property['price'] as String?) ?? '',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    (property['location'] as String?) ?? '',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: (property['isFavorite'] == true) ? 'favorite' : 'favorite_border',
                          label: (property['isFavorite'] == true) ? 'Saved' : 'Save',
                          onTap: () {
                            Navigator.pop(context);
                            widget.onFavoriteTap?.call(property);
                          },
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: 'share',
                          label: 'Share',
                          onTap: () {
                            Navigator.pop(context);
                            widget.onShareTap?.call(property);
                          },
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: 'phone',
                          label: 'Contact',
                          onTap: () {
                            Navigator.pop(context);
                            widget.onContactTap?.call(property);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
