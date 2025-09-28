import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:toletforrent/data/services/visit_service.dart';

class MyVisitsScreen extends StatelessWidget {
  const MyVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
          body: Center(child: Text('Sign in to view visits')));
    }
    final col = FirebaseFirestore.instance
        .collection('toletforrent_users')
        .doc(uid)
        .collection('visits')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Visits')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No visits yet'));
          return ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: docs.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final status = (d['status'] as String).toUpperCase();
              final title = (d['propertyTitle'] ?? 'Property') as String;
              final img = (d['propertyImage'] ?? '') as String;
              final start = (d['slotStart'] as Timestamp).toDate();
              final ownerId = d['ownerId'] as String;
              final propertyId = d['propertyId'] as String;
              final visitId = d['visitId'] as String;

              return Card(
                child: ListTile(
                  leading: img.isEmpty
                      ? const Icon(Icons.home)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(img,
                              width: 56, height: 56, fit: BoxFit.cover)),
                  title: Text(title),
                  subtitle:
                      Text(DateFormat('EEE, dd MMM • hh:mm a').format(start)),
                  trailing: _buildStatusPill(context, status),
                  onTap: () {},
                  onLongPress: () async {
                    if ((d['status'] as String) == 'pending') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cancel visit?'),
                          content:
                              const Text('This will withdraw your request.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Yes')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await VisitService().cancelVisit(
                            visitId: visitId,
                            propertyId: propertyId,
                            ownerId: ownerId);
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, String status) {
    Color bg;
    switch (status) {
      case 'CONFIRMED':
        bg = Colors.green;
        break;
      case 'DECLINED':
        bg = Colors.red;
        break;
      case 'CANCELED':
        bg = Colors.grey;
        break;
      default:
        bg = Colors.orange; // pending
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bg.withOpacity(0.35))),
      child: Text(status,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
    );
  }
}
