class AuthRequest {
  final String url;
  final String database;
  final String login;
  final String password;

  AuthRequest({
    required this.url,
    required this.database,
    required this.login,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'database': database,
        'login': login,
        'password': password,
      };
}

class AuthResponse {
  final String status;
  final String? token;
  final String? message;

  AuthResponse({required this.status, this.token, this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'],
      token: json['token'],
      message: json['message'],
    );
  }
}
