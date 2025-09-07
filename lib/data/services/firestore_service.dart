import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService I = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  /// Example: Property CRUD
  Future<String> addProperty(String ownerUid, Map<String, dynamic> data) async {
    final doc = await _db.collection('properties').add({
      ...data,
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active', // draft|active|archived
    });
    return doc.id;
  }

  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) {
    return _db.collection('properties').doc(propertyId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myProperties(String ownerUid) {
    return _db.collection('properties')
      .where('ownerUid', isEqualTo: ownerUid)
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
  }
}
