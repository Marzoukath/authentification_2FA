class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final dynamic errors;
  final bool? requires2fa;
  final String? twoFactorMethod;
  final int? userId;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.requires2fa,
    this.twoFactorMethod,
    this.userId,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
      errors: json['errors'],
      requires2fa: json['requires_2fa'],
      twoFactorMethod: json['two_factor_method'],
      userId: json['user_id'],
    );
  }
}