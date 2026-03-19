class User {
  final String username;
  final String role;
  final String token; // El JWT que genera tu Node.js

  User({
    required this.username, 
    required this.role, 
    required this.token
  });

  // Mapeo profesional de los datos que vienen de tu Backend 1
  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      username: json['Username'] ?? 'Sin nombre',
      role: json['Role'] ?? 'Vendedor',
      token: token,
    );
  }
}