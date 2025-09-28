import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toletforrent/core/app_export.dart';
import 'package:toletforrent/data/services/visit_service.dart';

class ScheduleVisitSheet extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String propertyImage; // pass primary image if any
  final String ownerId;
  const ScheduleVisitSheet({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImage,
    required this.ownerId,
  });

  @override
  State<ScheduleVisitSheet> createState() => _ScheduleVisitSheetState();
}

class _ScheduleVisitSheetState extends State<ScheduleVisitSheet> {
  final _svc = VisitService();
  DateTime _day = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 11, minute: 0);
  int _durationMin = 30;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Schedule a Visit',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: 2.h),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      initialDate: _day,
                    );
                    if (picked != null) setState(() => _day = picked);
                  },
                  child: Text(DateFormat('EEE, dd MMM').format(_day)),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _start);
                    if (picked != null) setState(() => _start = picked);
                  },
                  child: Text(_start.format(context)),
                ),
              ),
            ]),
            SizedBox(height: 1.h),
            Row(children: [
              const Text('Duration'),
              const Spacer(),
              DropdownButton<int>(
                value: _durationMin,
                items: const [30, 45, 60, 90]
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text('$m min')))
                    .toList(),
                onChanged: (v) => setState(() => _durationMin = v ?? 30),
              )
            ]),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Anything the owner should know?'),
              maxLines: 2,
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Sending…' : 'Request Visit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final dtStart =
        DateTime(_day.year, _day.month, _day.day, _start.hour, _start.minute);
    final dtEnd = dtStart.add(Duration(minutes: _durationMin));

    setState(() => _submitting = true);
    try {
      await _svc.requestVisit(
        propertyId: widget.propertyId,
        propertyTitle: widget.propertyTitle,
        propertyImage: widget.propertyImage,
        ownerId: widget.ownerId,
        slotStart: dtStart,
        slotEnd: dtEnd,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Visit request sent')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
