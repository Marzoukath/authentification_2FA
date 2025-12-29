class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool twoFactorEnabled;
  final String twoFactorMethod;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.twoFactorEnabled,
    required this.twoFactorMethod,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      twoFactorMethod: json['two_factor_method'] ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'two_factor_enabled': twoFactorEnabled,
      'two_factor_method': twoFactorMethod,
    };
  }
}