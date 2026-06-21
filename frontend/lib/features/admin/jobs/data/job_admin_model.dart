import 'package:equatable/equatable.dart';

class JobAdminModel extends Equatable {
  final int id;
  final String jobCode;
  final String jobDescription;
  final bool isActive;

  const JobAdminModel({
    required this.id,
    required this.jobCode,
    required this.jobDescription,
    required this.isActive,
  });

  factory JobAdminModel.fromJson(Map<String, dynamic> json) {
    return JobAdminModel(
      id: json['id'] as int,
      jobCode: json['job_code'] as String,
      jobDescription: json['job_description'] as String,
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
    );
  }

  @override
  List<Object?> get props => [id, jobCode, jobDescription, isActive];
}
