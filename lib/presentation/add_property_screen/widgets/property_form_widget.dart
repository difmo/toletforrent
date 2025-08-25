import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PropertyFormWidget extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController rentController;
  final TextEditingController depositController;
  final TextEditingController locationController;
  final DateTime? availabilityDate;
  final bool showPhone;
  final bool showWhatsApp;
  final ValueChanged<DateTime?> onAvailabilityDateChanged;
  final ValueChanged<bool> onShowPhoneChanged;
  final ValueChanged<bool> onShowWhatsAppChanged;

  const PropertyFormWidget({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.rentController,
    required this.depositController,
    required this.locationController,
    required this.availabilityDate,
    required this.showPhone,
    required this.showWhatsApp,
    required this.onAvailabilityDateChanged,
    required this.onShowPhoneChanged,
    required this.onShowWhatsAppChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Details',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Provide essential information about your property',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 3.h),

        // Property Title
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Property Title *',
            hintText: 'e.g., Spacious 2BHK Apartment in Bandra',
          ),
          maxLength: 60,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Property title is required';
            }
            if (value.trim().length < 10) {
              return 'Title should be at least 10 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 2.h),

        // Monthly Rent
        TextFormField(
          controller: rentController,
          decoration: const InputDecoration(
            labelText: 'Monthly Rent (₹) *',
            hintText: 'e.g., 25000',
            prefixText: '₹ ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Monthly rent is required';
            }
            final amount = int.tryParse(value);
            if (amount == null || amount < 1000) {
              return 'Please enter a valid rent amount';
            }
            return null;
          },
        ),
        SizedBox(height: 2.h),

        // Security Deposit
        TextFormField(
          controller: depositController,
          decoration: const InputDecoration(
            labelText: 'Security Deposit (₹)',
            hintText: 'e.g., 50000',
            prefixText: '₹ ',
            helperText: 'Optional - typically 1-2 months rent',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final amount = int.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Please enter a valid deposit amount';
              }
            }
            return null;
          },
        ),
        SizedBox(height: 2.h),

        // Location
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: 'Location *',
            hintText: 'e.g., Bandra West, Mumbai',
            suffixIcon: IconButton(
              onPressed: () {
                // TODO: Implement location picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location picker coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: CustomIconWidget(
                iconName: 'location_on',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          maxLength: 100,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Location is required';
            }
            if (value.trim().length < 5) {
              return 'Please enter a more specific location';
            }
            return null;
          },
        ),
        SizedBox(height: 2.h),

        // Description
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your property, nearby amenities, etc.',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: 500,
          validator: (value) {
            if (value != null &&
                value.trim().isNotEmpty &&
                value.trim().length < 20) {
              return 'Description should be at least 20 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 3.h),

        // Availability Date
        GestureDetector(
          onTap: () => _selectAvailabilityDate(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available From',
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      availabilityDate != null
                          ? '${availabilityDate!.day}/${availabilityDate!.month}/${availabilityDate!.year}'
                          : 'Select Date',
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // Contact Preferences
        Text(
          'Contact Preferences',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Choose how potential tenants can contact you',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 2.h),

        // Phone visibility toggle
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SwitchListTile(
            title: Text(
              'Show Phone Number',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Tenants can call you directly',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            value: showPhone,
            onChanged: onShowPhoneChanged,
          ),
        ),
        SizedBox(height: 2.h),

        // WhatsApp visibility toggle
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SwitchListTile(
            title: Text(
              'Show WhatsApp',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Tenants can message you on WhatsApp',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            value: showWhatsApp,
            onChanged: onShowWhatsAppChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _selectAvailabilityDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          availabilityDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      onAvailabilityDateChanged(picked);
    }
  }
}
