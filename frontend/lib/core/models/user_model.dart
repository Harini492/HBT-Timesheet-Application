import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String employeeCode;
  final String name;
  final String? email;
  final String role; // 'admin' | 'employee'

  const UserModel({
    required this.id,
    required this.employeeCode,
    required this.name,
    this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      employeeCode: (json['employeeCode'] ?? json['employee_code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: json['email'] as String?,
      role: (json['role'] ?? 'employee') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeCode': employeeCode,
        'name': name,
        'email': email,
        'role': role,
      };

  @override
  List<Object?> get props => [id, employeeCode, name, email, role];
}
