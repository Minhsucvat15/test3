class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarSeed; // dùng để render avatar gradient
  final String passwordHash;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.createdAt,
    this.avatarSeed,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'].toString(),
        email: j['email'].toString(),
        displayName: j['displayName']?.toString() ?? 'User',
        passwordHash: j['passwordHash']?.toString() ?? '',
        avatarSeed: j['avatarSeed']?.toString(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'passwordHash': passwordHash,
        'avatarSeed': avatarSeed,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? displayName,
    String? avatarSeed,
    String? passwordHash,
  }) =>
      UserModel(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        avatarSeed: avatarSeed ?? this.avatarSeed,
        passwordHash: passwordHash ?? this.passwordHash,
        createdAt: createdAt,
      );
}
