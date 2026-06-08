enum UserRole { superAdmin, user }

class UserModel {
  final String? uid;
  final String name;
  final String email;
  final UserRole role;
  final String profilePicture;
  final String phoneNumber;

  UserModel({
    this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profilePicture = 'https://ui-avatars.com/api/?name=User',
    this.phoneNumber = '',
  });

  static final UserModel empty = UserModel(
    uid: '',
    name: 'Loading...',
    email: '',
    role: UserRole.user,
    profilePicture: 'https://ui-avatars.com/api/?name=Loading',
    phoneNumber: '',
  );

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'profilePicture': profilePicture,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: _parseRole(map['role'] as String? ?? 'user'),
      profilePicture:
          map['profilePicture'] as String? ??
          'https://ui-avatars.com/api/?name=User',
      phoneNumber: map['phoneNumber'] as String? ?? '',
    );
  }

  static UserRole _parseRole(String roleName) {
    if (roleName == 'superAdmin') return UserRole.superAdmin;
    return UserRole.user;
  }
}
