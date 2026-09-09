class UserModel {
  final String username;
  final String displayName;
  final String role;
  final DateTime lastLogin;

  const UserModel({
    required this.username,
    required this.displayName,
    this.role = 'Producer / Musician',
    required this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'role': role,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'] ?? 'admin',
      displayName: map['displayName'] ?? 'Admin Studio',
      role: map['role'] ?? 'Producer / Musician',
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'])
          : DateTime.now(),
    );
  }
}
