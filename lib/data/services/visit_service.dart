import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toletforrent/data/models/visits/visit_models.dart';


class VisitService {
final FirebaseFirestore db;
final FirebaseAuth auth;
VisitService({FirebaseFirestore? db, FirebaseAuth? auth})
: db = db ?? FirebaseFirestore.instance,
auth = auth ?? FirebaseAuth.instance;
// Create a visit request (tenant only)
Future<String> requestVisit({
required String propertyId,
required String propertyTitle,
required String propertyImage,
required String ownerId,
required DateTime slotStart,
required DateTime slotEnd,
String? note,

}) async {
final user = auth.currentUser;
if (user == null) throw Exception('Sign in to request a visit');
if (user.uid == ownerId) {
throw Exception('Owners cannot schedule on their own listing');
}


final tenantName = user.displayName ?? 'Tenant';
final tenantPhone = user.phoneNumber ?? '';


final visitCol = db.collection('properties').doc(propertyId).collection('visits');
final visitRef = visitCol.doc();
final visitId = visitRef.id;


final visit = VisitRequest(
  visitId: visitId,
propertyId: propertyId,
propertyTitle: propertyTitle,
propertyImage: propertyImage,
ownerId: ownerId,
tenantId: user.uid,
tenantName: tenantName,
tenantPhone: tenantPhone,
status: VisitStatus.pending,
slotStart: Timestamp.fromDate(slotStart),
slotEnd: Timestamp.fromDate(slotEnd),
note: note,
);  
// Optional: quick conflict check on confirmed visits (best-effort)
final existing = await visitCol
.where('status', isEqualTo: 'confirmed')
.where('slotStart', isLessThan: Timestamp.fromDate(slotEnd))
.orderBy('slotStart', descending: false)
.limit(25)
.get();
for (final doc in existing.docs) {
final s = doc['slotStart'] as Timestamp;
final e = doc['slotEnd'] as Timestamp;
final overlap = s.toDate().isBefore(slotEnd) && e.toDate().isAfter(slotStart);
if (overlap) {
throw Exception('Time slot overlaps an existing confirmed visit');
}
}


final batch = db.batch();
final tenantMirror = db.collection('toletforrent_users').doc(user.uid).collection('visits').doc(visitId);
final ownerMirror = db.collection('toletforrent_users').doc(ownerId).collection('visits').doc(visitId);


batch.set(visitRef, visit.toMap());
batch.set(tenantMirror, visit.toMap());
batch.set(ownerMirror, visit.toMap());


await batch.commit();
return visitId;
}
// Tenant can cancel while pending
Future<void> cancelVisit({
required String visitId,
required String propertyId,
required String ownerId,
}) async {
final uid = auth.currentUser?.uid;
if (uid == null) throw Exception('Sign in');


final p = db.collection('properties').doc(propertyId).collection('visits').doc(visitId);
final t = db.collection('toletforrent_users').doc(uid).collection('visits').doc(visitId);
final o = db.collection('toletforrent_users').doc(ownerId).collection('visits').doc(visitId);


final snap = await p.get();
if (!snap.exists) throw Exception('Visit not found');
if (snap['tenantId'] != uid) throw Exception('Not your visit');
if (snap['status'] != 'pending') throw Exception('Only pending can be canceled');


final batch = db.batch();
final data = {'status': 'canceled', 'updatedAt': FieldValue.serverTimestamp()};
batch.set(p, data, SetOptions(merge: true));
batch.set(t, data, SetOptions(merge: true));
batch.set(o, data, SetOptions(merge: true));
await batch.commit();
}

// Owner confirms or declines
Future<void> ownerRespond({
required String visitId,
required String propertyId,
required String ownerId,
required bool confirm,
String? ownerResponseNote,
}) async {
final uid = auth.currentUser?.uid;
if (uid == null) throw Exception('Sign in');
if (uid != ownerId) throw Exception('Only the owner can respond');


final p = db.collection('properties').doc(propertyId).collection('visits').doc(visitId);
final pSnap = await p.get();
if (!pSnap.exists) throw Exception('Visit not found');
final tenantId = pSnap['tenantId'] as String;


final status = confirm ? 'confirmed' : 'declined';


final data = {
'status': status,
if (ownerResponseNote != null) 'ownerResponseNote': ownerResponseNote,
'updatedAt': FieldValue.serverTimestamp(),
};


final t = db.collection('toletforrent_users').doc(tenantId).collection('visits').doc(visitId);
final o = db.collection('toletforrent_users').doc(ownerId).collection('visits').doc(visitId);


final batch = db.batch();
batch.set(p, data, SetOptions(merge: true));
batch.set(t, data, SetOptions(merge: true));
batch.set(o, data, SetOptions(merge: true));
await batch.commit();
}
}