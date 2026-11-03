import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });
  final int id;
  final String name;
  final String email;
  final String phone;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
  );

  @override
  List<Object> get props => [id, name, email, phone];
}
