/// Tabel categories: id, name, description.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
  });

  final int id;
  final String name;
  final String description;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}
