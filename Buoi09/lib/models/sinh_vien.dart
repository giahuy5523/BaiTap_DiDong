class SinhVien {
  final int? id;
  final String name;
  final String email;

  const SinhVien({
    this.id,
    required this.name,
    required this.email,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
    };
  }

  factory SinhVien.fromMap(Map<String, Object?> map) {
    return SinhVien(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
    );
  }
}