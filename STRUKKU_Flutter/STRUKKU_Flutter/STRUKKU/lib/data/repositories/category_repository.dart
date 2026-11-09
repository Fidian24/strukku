import '../../models/category_model.dart';
import '../local/app_database.dart';

/// Kontrak pengambilan daftar kategori.
abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
}

/// Kategori dari tabel categories di SQLite lokal.
class LocalCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('categories', orderBy: 'id');
    return rows.map(CategoryModel.fromJson).toList();
  }
}
