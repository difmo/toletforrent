class AppUser {
  final String uid;
  final String phone;
  final String? email;
  final String? displayName;
  final String role; // "user" | "agent" | "admin"
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.phone,
    this.email,
    this.displayName,
    this.role = 'user',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'phone': phone,
        'email': email,
        'displayName': displayName,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'],
        displayName: map['displayName'],
        role: map['role'] ?? 'user',
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      );
}
