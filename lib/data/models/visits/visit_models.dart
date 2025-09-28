import 'package:cloud_firestore/cloud_firestore.dart';


enum VisitStatus {
pending,
confirmed,
declined,
canceled,
completed,
noShow,
}


String visitStatusToString(VisitStatus s) {
switch (s) {
case VisitStatus.pending: return 'pending';
case VisitStatus.confirmed: return 'confirmed';
case VisitStatus.declined: return 'declined';
case VisitStatus.canceled: return 'canceled';
case VisitStatus.completed: return 'completed';
case VisitStatus.noShow: return 'no_show';
}
}

VisitStatus visitStatusFromString(String s) {
switch (s) {
case 'confirmed': return VisitStatus.confirmed;
case 'declined' : return VisitStatus.declined;
case 'canceled' : return VisitStatus.canceled;
case 'completed': return VisitStatus.completed;
case 'no_show' : return VisitStatus.noShow;
case 'pending' :
default: return VisitStatus.pending;
}
}
class VisitRequest {
final String visitId;
final String propertyId;
final String propertyTitle;
final String propertyImage;
final String ownerId;
final String tenantId;
final String tenantName;
final String tenantPhone;
final VisitStatus status;
final Timestamp slotStart;
final Timestamp slotEnd;
final String? note;
final String? ownerResponseNote;
final Timestamp? createdAt;
final Timestamp? updatedAt;


VisitRequest({
required this.visitId,
required this.propertyId,
required this.propertyTitle,
required this.propertyImage,
required this.ownerId,
required this.tenantId,
required this.tenantName,
required this.tenantPhone,
required this.status,
required this.slotStart,
required this.slotEnd,
this.note,
this.ownerResponseNote,
this.createdAt,
this.updatedAt,
});

Map<String, dynamic> toMap() => {
'visitId': visitId,
'propertyId': propertyId,
'propertyTitle': propertyTitle,
'propertyImage': propertyImage,
'ownerId': ownerId,
'tenantId': tenantId,
'tenantName': tenantName,
'tenantPhone': tenantPhone,
'status': visitStatusToString(status),
'slotStart': slotStart,
'slotEnd': slotEnd,
if (note != null) 'note': note,
if (ownerResponseNote != null) 'ownerResponseNote': ownerResponseNote,
'createdAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),
};

factory VisitRequest.fromSnap(DocumentSnapshot<Map<String, dynamic>> s) {
final d = s.data()!;
return VisitRequest(
visitId: d['visitId'] as String,
propertyId: d['propertyId'] as String,
propertyTitle: (d['propertyTitle'] ?? '') as String,
propertyImage: (d['propertyImage'] ?? '') as String,
ownerId: d['ownerId'] as String,
tenantId: d['tenantId'] as String,
tenantName: (d['tenantName'] ?? '') as String,
tenantPhone: (d['tenantPhone'] ?? '') as String,
status: visitStatusFromString(d['status'] as String),
slotStart: d['slotStart'] as Timestamp,
slotEnd: d['slotEnd'] as Timestamp,
note: d['note'] as String?,
ownerResponseNote: d['ownerResponseNote'] as String?,
createdAt: d['createdAt'] as Timestamp?,
updatedAt: d['updatedAt'] as Timestamp?,
);
}
}