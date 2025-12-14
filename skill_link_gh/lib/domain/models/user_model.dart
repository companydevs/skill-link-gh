class UserModel {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String userType; // artisan or fixer
  final String? businessName;
  final String? businessDescription;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.userType,
    this.businessName,
    this.businessDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'userType': userType,
      'businessName': businessName,
      'businessDescription': businessDescription,
    };
  }
}
