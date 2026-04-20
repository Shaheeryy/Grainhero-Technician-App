class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;
  final String? hasAccess;
  final List<String> assignedSites;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    this.hasAccess,
    this.assignedSites = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      role: json['role'] ?? 'technician',
      avatar: json['avatar'],
      hasAccess: json['hasAccess'],
      assignedSites: json['assignedSites'] != null
          ? List<String>.from(json['assignedSites'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'hasAccess': hasAccess,
      'assignedSites': assignedSites,
    };
  }
}
