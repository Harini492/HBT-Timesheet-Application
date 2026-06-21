import 'package:equatable/equatable.dart';

class Holiday extends Equatable {
  final int id;
  final String date;
  final String name;

  const Holiday({required this.id, required this.date, required this.name});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] as int,
      date: (json['holiday_date'] ?? json['date']) as String,
      name: json['name'] as String,
    );
  }

  @override
  List<Object?> get props => [id, date, name];
}
