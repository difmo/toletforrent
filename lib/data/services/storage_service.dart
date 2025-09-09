import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

typedef Progress = void Function(double percent);

class StorageService {
  StorageService._();
  static final StorageService I = StorageService._();

  final _storage = FirebaseStorage.instance;

  /// Uploads and returns download URL
  Future<String> uploadUserFile({
    required String uid,
    required File file,
    required String destFileName, // e.g. "frontid.jpg"
    Progress? onProgress,
  }) async {
    final ref = _storage.ref().child('users/$uid/uploads/$destFileName');
    final task = ref.putFile(file);

    task.snapshotEvents.listen((TaskSnapshot snap) {
      final p = (snap.bytesTransferred / (snap.totalBytes == 0 ? 1 : snap.totalBytes)) * 100;
      onProgress?.call(p.clamp(0, 100));
    });

    final snap = await task;
    return snap.ref.getDownloadURL();
  }
}
