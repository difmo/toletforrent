import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ImageUploadWidget extends StatelessWidget {
  final List<XFile> images;
  final int primaryImageIndex;
  final VoidCallback onPickImages;
  final VoidCallback onTakePicture;
  final Function(int) onRemoveImage;
  final Function(int, int) onReorderImages;
  final Function(int) onSetPrimaryImage;

  const ImageUploadWidget({
    super.key,
    required this.images,
    required this.primaryImageIndex,
    required this.onPickImages,
    required this.onTakePicture,
    required this.onRemoveImage,
    required this.onReorderImages,
    required this.onSetPrimaryImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Images',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Add photos to showcase your property. First image will be the cover photo.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 3.h),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickImages,
                icon: CustomIconWidget(
                  iconName: 'photo_library',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                label: const Text('Gallery'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onTakePicture,
                icon: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),

        // Images Grid
        if (images.isEmpty) _buildEmptyState() else _buildImagesGrid(),

        SizedBox(height: 2.h),

        // Guidelines
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lightbulb_outline',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Photo Tips',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.w),
              _buildTip('• Take photos in good lighting'),
              _buildTip('• Include all rooms and amenities'),
              _buildTip('• Show different angles of the property'),
              _buildTip('• Maximum 10 photos allowed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 30.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'add_photo_alternate',
            size: 60,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.4),
          ),
          SizedBox(height: 2.h),
          Text(
            'No photos added yet',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add photos using gallery or camera',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${images.length}/10 photos added',
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 1.h),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          onReorder: onReorderImages,
          itemBuilder: (context, index) {
            return _ImageCard(
              key: ValueKey(images[index].path),
              image: images[index],
              index: index,
              isPrimary: index == primaryImageIndex,
              onRemove: () => onRemoveImage(index),
              onSetPrimary: () => onSetPrimaryImage(index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.w),
      child: Text(
        tip,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color:
              AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final XFile image;
  final int index;
  final bool isPrimary;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  const _ImageCard({
    super.key,
    required this.image,
    required this.index,
    required this.isPrimary,
    required this.onRemove,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          // Drag Handle
          CustomIconWidget(
            iconName: 'drag_indicator',
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.5),
            size: 24,
          ),
          SizedBox(width: 2.w),

          // Image Preview
          Container(
            width: 20.w,
            height: 15.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isPrimary
                  ? Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: kIsWeb
                        ? Image.network(
                            image.path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error, size: 30),
                          )
                        : Image.file(
                            File(image.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error, size: 30),
                          ),
                  ),
                  if (isPrimary)
                    Positioned(
                      top: 1.w,
                      left: 1.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 1.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'COVER',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Image Info and Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo ${index + 1}',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.w),
                if (isPrimary)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Cover Photo',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: onSetPrimary,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'Set as Cover',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                SizedBox(height: 1.w),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onRemove,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        minimumSize: Size.zero,
                      ),
                      icon: CustomIconWidget(
                        iconName: 'delete_outline',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 16,
                      ),
                      label: Text(
                        'Remove',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
