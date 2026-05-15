class UserModel {
  final String? uid; // Tambahkan UID dari Firebase
  final String fullName;
  final String email;
  final String? profilePictureUrl;
  final String? role;

  UserModel({
    this.uid,
    required this.fullName,
    required this.email,
    this.profilePictureUrl,
    this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'profilePictureUrl': profilePictureUrl ?? '',
      'role': role ?? 'user',
    };
  }

  // Untuk mengambil data dari Firestore ke aplikasi
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      fullName: map['fullName'],
      email: map['email'],
      profilePictureUrl: map['profilePictureUrl'],
      role: map['role'],
    );
  }
}
