class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String tipoUsuario;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.tipoUsuario,
    required this.accessToken,
    required this.refreshToken,
  });

  // El backend retorna: { usuario: { id, nombre, email, tipo_usuario }, accessToken, refreshToken }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>?;

    return UserModel(
      id: usuario?['id'] ?? json['id'] ?? json['_id'] ?? '',
      nombre: usuario?['nombre'] ?? json['nombre'] ?? '',
      email: usuario?['email'] ?? json['email'] ?? '',
      tipoUsuario: usuario?['tipo_usuario'] ?? json['tipo_usuario'] ?? '',
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario': {
        'id': id,
        'nombre': nombre,
        'email': email,
        'tipo_usuario': tipoUsuario,
      },
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
