import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/amenities_selection_widget.dart';
import './widgets/draft_save_widget.dart';
import './widgets/image_upload_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/property_form_widget.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _locationController = TextEditingController();

  // Form State
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isDraftSaving = false;
  List<XFile> _propertyImages = [];
  int _primaryImageIndex = 0;

  // Property Details
  String _bhkCount = '1 BHK';
  String _propertyType = 'Apartment';
  String _furnishedStatus = 'Semi-Furnished';
  DateTime? _availabilityDate = DateTime.now().add(const Duration(days: 7));

  // Amenities
  Set<String> _selectedAmenities = {};

  // Contact Preferences
  bool _showPhone = true;
  bool _showWhatsApp = true;

  final List<String> _bhkOptions = [
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4+ BHK',
    'Studio'
  ];
  final List<String> _propertyTypes = [
    'Apartment',
    'House',
    'Villa',
    'PG',
    'Hostel',
    'Flat'
  ];
  final List<String> _furnishedOptions = [
    'Furnished',
    'Semi-Furnished',
    'Unfurnished'
  ];

  final List<Map<String, dynamic>> _availableAmenities = [
    {'name': 'Parking', 'icon': 'local_parking'},
    {'name': 'Gym', 'icon': 'fitness_center'},
    {'name': '24/7 Security', 'icon': 'security'},
    {'name': 'Power Backup', 'icon': 'power'},
    {'name': 'Lift', 'icon': 'elevator'},
    {'name': 'Swimming Pool', 'icon': 'pool'},
    {'name': 'Garden', 'icon': 'local_florist'},
    {'name': 'Playground', 'icon': 'sports_soccer'},
    {'name': 'CCTV', 'icon': 'videocam'},
    {'name': 'Water Supply', 'icon': 'water_drop'},
    {'name': 'Internet/WiFi', 'icon': 'wifi'},
    {'name': 'Air Conditioning', 'icon': 'ac_unit'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDraftData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDraftData() async {
    // Simulate loading draft data from local storage
    await Future.delayed(const Duration(milliseconds: 500));
    // Implementation would load from SharedPreferences or local database
  }

  Future<void> _saveDraft() async {
    setState(() {
      _isDraftSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    // Save form data to local storage

    setState(() {
      _isDraftSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();

      if (images != null && images.isNotEmpty) {
        setState(() {
          _propertyImages.addAll(images);
          if (_propertyImages.length > 10) {
            _propertyImages = _propertyImages.take(10).toList();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${images.length} images added'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick images'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _propertyImages.add(image);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to capture photo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _propertyImages.removeAt(index);
      if (_primaryImageIndex >= _propertyImages.length) {
        _primaryImageIndex = _propertyImages.isNotEmpty ? 0 : 0;
      }
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _propertyImages.removeAt(oldIndex);
      _propertyImages.insert(newIndex, item);

      // Update primary index if needed
      if (_primaryImageIndex == oldIndex) {
        _primaryImageIndex = newIndex;
      }
    });
  }

  void _setPrimaryImage(int index) {
    setState(() {
      _primaryImageIndex = index;
    });
  }

  void _onAmenityToggle(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Images step
        if (_propertyImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add at least one property image'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;

      case 1: // Basic details step
        if (!_formKey.currentState!.validate()) {
          return false;
        }
        return true;

      case 2: // Property configuration step
        return true;

      case 3: // Amenities step
        return true;

      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
        });
        _saveDraft();
      } else {
        _previewListing();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _previewListing() {
    if (_formKey.currentState!.validate() && _propertyImages.isNotEmpty) {
      // Navigate to preview screen
      _showPreviewBottomSheet();
    }
  }

  Future<void> _publishProperty() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call to publish property
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/property-detail-screen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property published successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish property'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPreviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
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
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview Listing',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: _buildPreviewContent(),
              ),
            ),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color:
                        AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Edit'),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                              _publishProperty();
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Publish Property'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images preview
        if (_propertyImages.isNotEmpty) ...[
          Container(
            height: 25.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(
                      _propertyImages[_primaryImageIndex].path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, size: 50),
                    )
                  : Image.file(
                      File(_propertyImages[_primaryImageIndex].path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, size: 50),
                    ),
            ),
          ),
          SizedBox(height: 2.h),
        ],

        // Property details preview
        Text(
          _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Property Title',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),

        Text(
          _rentController.text.isNotEmpty
              ? '₹${_rentController.text}/month'
              : '₹0/month',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),

        Row(
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
              size: 16,
            ),
            SizedBox(width: 1.w),
            Expanded(
              child: Text(
                _locationController.text.isNotEmpty
                    ? _locationController.text
                    : 'Location',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Property config
        Row(
          children: [
            _buildInfoChip(_bhkCount, Icons.home),
            SizedBox(width: 2.w),
            _buildInfoChip(_propertyType, Icons.apartment),
            SizedBox(width: 2.w),
            _buildInfoChip(_furnishedStatus, Icons.chair),
          ],
        ),
        SizedBox(height: 2.h),

        // Description
        if (_descriptionController.text.isNotEmpty) ...[
          Text(
            'Description',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _descriptionController.text,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
        ],

        // Amenities
        if (_selectedAmenities.isNotEmpty) ...[
          Text(
            'Amenities',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _selectedAmenities
                .map((amenity) => _buildAmenityChip(amenity))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(width: 1.w),
          Text(
            text,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(String amenity) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        amenity,
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Property'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          DraftSaveWidget(
            onSave: _saveDraft,
            isLoading: _isDraftSaving,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          ProgressIndicatorWidget(
            currentStep: _currentStep,
            totalSteps: 4,
            stepTitles: const ['Images', 'Details', 'Config', 'Amenities'],
          ),

          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(4.w),
                child: _buildCurrentStepContent(),
              ),
            ),
          ),

          // Bottom Navigation
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color:
                      AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 4.w),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 3 ? 'Preview Listing' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return ImageUploadWidget(
          images: _propertyImages,
          primaryImageIndex: _primaryImageIndex,
          onPickImages: _pickImages,
          onTakePicture: _takePicture,
          onRemoveImage: _removeImage,
          onReorderImages: _reorderImages,
          onSetPrimaryImage: _setPrimaryImage,
        );

      case 1:
        return PropertyFormWidget(
          titleController: _titleController,
          descriptionController: _descriptionController,
          rentController: _rentController,
          depositController: _depositController,
          locationController: _locationController,
          availabilityDate: _availabilityDate,
          showPhone: _showPhone,
          showWhatsApp: _showWhatsApp,
          onAvailabilityDateChanged: (date) {
            setState(() {
              _availabilityDate = date;
            });
          },
          onShowPhoneChanged: (value) {
            setState(() {
              _showPhone = value;
            });
          },
          onShowWhatsAppChanged: (value) {
            setState(() {
              _showWhatsApp = value;
            });
          },
        );

      case 2:
        return _buildPropertyConfigStep();

      case 3:
        return AmenitiesSelectionWidget(
          availableAmenities: _availableAmenities,
          selectedAmenities: _selectedAmenities,
          onAmenityToggle: _onAmenityToggle,
        );

      default:
        return Container();
    }
  }

  Widget _buildPropertyConfigStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Configuration',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Specify the type and configuration of your property',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 3.h),

        // BHK Selection
        Text(
          'BHK Count',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _bhkCount,
              isExpanded: true,
              items: _bhkOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _bhkCount = value;
                  });
                }
              },
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // Property Type Selection
        Text(
          'Property Type',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _propertyType,
              isExpanded: true,
              items: _propertyTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _propertyType = value;
                  });
                }
              },
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // Furnished Status Selection
        Text(
          'Furnished Status',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _furnishedStatus,
              isExpanded: true,
              items: _furnishedOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _furnishedStatus = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
