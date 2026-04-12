class AppUser {
  final String name;
  final String email;
  final String role;

  const AppUser({
    required this.name,
    required this.email,
    this.role = 'Administrador',
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, String> map) {
    return AppUser(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Administrador',
    );
  }
}
