import 'package:skill_link_gh/domain/models/userTypes.dart';

class UserModel {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final UserType userType; // enum
  final String businessName;
  final String businessDescription;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.userType,
    String? businessName,
    String? businessDescription,
  })  : businessName = userType == UserType.artisan
            ? (businessName ?? '')
            : '', // always non-null for artisan
        businessDescription = userType == UserType.artisan
            ? (businessDescription ?? '')
            : ''; // always non-null for artisan

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'userType': userType.name, // enum as string
      'businessName': businessName,
      'description': businessDescription, // match backend field name
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final type = UserType.values.firstWhere(
      (e) => e.name == (json['userType'] ?? 'client'),
      orElse: () => UserType.client,
    );
    return UserModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      userType: type,
      businessName: json['businessName'],
      businessDescription: json['description'], // match backend
    );
  }
}
