import '../../../utils/json_helpers.dart';

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.categoryName,
  });

  final int id;
  final String categoryName;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: JsonHelpers.pickInt(json, [
            'id',
            'Id',
            'category_id',
            'Category_id',
            'categoryId',
            'CategoryId',
          ]) ??
          0,
      categoryName: JsonHelpers.pickString(json, [
            'category_Name',
            'categoryName',
            'CategoryName',
            'name',
            'Name',
          ]) ??
          '',
    );
  }
}

class WorkerCategoryItem {
  const WorkerCategoryItem({
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  factory WorkerCategoryItem.fromJson(Map<String, dynamic> json) {
    return WorkerCategoryItem(
      categoryId: JsonHelpers.pickInt(json, [
            'category_id',
            'Category_id',
            'categoryId',
            'CategoryId',
            'id',
            'Id',
            'fk_category_ID',
            'FK_category_ID',
          ]) ??
          0,
      categoryName: JsonHelpers.pickString(json, [
            'category_Name',
            'categoryName',
            'CategoryName',
            'name',
            'Name',
          ]) ??
          '',
    );
  }
}
