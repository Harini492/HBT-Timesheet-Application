import 'package:equatable/equatable.dart';

class EmployeeAdminModel extends Equatable {
  final int id;
  final String employeeCode;
  final String name;
  final String? email;
  final String role;
  final bool isActive;

  const EmployeeAdminModel({
    required this.id,
    required this.employeeCode,
    required this.name,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory EmployeeAdminModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAdminModel(
      id: json['id'] as int,
      employeeCode: json['employee_code'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
    );
  }

  @override
  List<Object?> get props => [id, employeeCode, name, email, role, isActive];
}
