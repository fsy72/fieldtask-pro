import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({required super.id, required super.name, required super.email});

  factory AppUserModel.fromJson(Map<String, dynamic> json) => AppUserModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };
}
