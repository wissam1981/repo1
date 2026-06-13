class User {
  final int id;
  final String email;
  final String authProvider;
  final String cerfLevel;

  User({
    required this.id,
    required this.email,
    required this.authProvider,
    this.cerfLevel = 'A1',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      authProvider: json['auth_provider'],
      cerfLevel: json['cefr_level'] ?? 'A1',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'auth_provider': authProvider,
    'cefr_level': cerfLevel,
  };
}
