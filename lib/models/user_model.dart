class UserModel {
  final String idUsuario;
  final String nombre;
  final String email;
  final String accessToken;

  UserModel({
    required this.idUsuario,
    required this.nombre,
    required this.email,
    required this.accessToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUsuario: json['id_usuario'] ?? json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      accessToken: json['access_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'email': email,
      'access_token': accessToken,
    };
  }
}
