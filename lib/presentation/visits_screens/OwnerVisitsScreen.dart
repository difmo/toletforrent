import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:toletforrent/data/services/visit_service.dart';


class OwnerVisitsScreen extends StatelessWidget {
const OwnerVisitsScreen({super.key});


@override
Widget build(BuildContext context) {
final ownerId = FirebaseAuth.instance.currentUser?.uid;
if (ownerId == null) {
return const Scaffold(body: Center(child: Text('Sign in as owner')));
}
final col = FirebaseFirestore.instance
.collection('toletforrent_users').doc(ownerId)
.collection('visits')
.orderBy('createdAt', descending: true);

return Scaffold(
appBar: AppBar(title: const Text('Visit Requests')),
body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
stream: col.snapshots(),
builder: (context, snap) {
if (!snap.hasData) return const Center(child: CircularProgressIndicator());
final docs = snap.data!.docs;
if (docs.isEmpty) return const Center(child: Text('No requests yet'));


return ListView.separated(
padding: EdgeInsets.all(4.w),
itemCount: docs.length,
separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
itemBuilder: (context, i) {
final d = docs[i].data();
final status = (d['status'] as String);
final title = (d['propertyTitle'] ?? 'Property') as String;
final img = (d['propertyImage'] ?? '') as String;
final start = (d['slotStart'] as Timestamp).toDate();
final tenant = (d['tenantName'] ?? 'Tenant') as String;
final visitId = d['visitId'] as String;
final propertyId = d['propertyId'] as String;



return Card(
child: ListTile(
leading: img.isEmpty ? const Icon(Icons.home) : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, width: 56, height: 56, fit: BoxFit.cover)),
title: Text(title),
subtitle: Text('${DateFormat('EEE, dd MMM • hh:mm a').format(start)}\nBy: $tenant'),
isThreeLine: true,
trailing: _ownerActions(context, status, () async {
await VisitService().ownerRespond(
visitId: visitId,
propertyId: propertyId,
ownerId: ownerId,
confirm: true,
);
}, () async {
final note = await _declineNoteDialog(context);
await VisitService().ownerRespond(
visitId: visitId,
propertyId: propertyId,
ownerId: ownerId,
confirm: false,
ownerResponseNote: note,
);
}),
),
);
},
);
},
),
);
}
Widget _ownerActions(BuildContext context, String status, VoidCallback onAccept, VoidCallback onDecline) {
if (status != 'pending') {
Color bg;
switch (status) { case 'confirmed': bg = Colors.green; break; case 'declined': bg = Colors.red; break; default: bg = Colors.grey; }
return Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: bg.withOpacity(0.35))),
child: Text(status.toUpperCase(), style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
);
}
return Row(mainAxisSize: MainAxisSize.min, children: [
IconButton(icon: const Icon(Icons.close), color: Colors.red, onPressed: onDecline),
IconButton(icon: const Icon(Icons.check), color: Colors.green, onPressed: onAccept),
]);
}


Future<String?> _declineNoteDialog(BuildContext context) async {
final ctrl = TextEditingController();
return showDialog<String?>(
context: context,
builder: (_) => AlertDialog(
title: const Text('Decline request?'),
content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reason (optional)')),
actions: [
TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Decline')),
],
),
);
}
}