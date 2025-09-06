import 'package:hive/hive.dart';

part 'favorite_model.g.dart';

@HiveType(typeId: 1)
class FavoriteModel extends HiveObject {
  @HiveField(0)
  final String serviceId;
  
  @HiveField(1)
  final DateTime addedAt;
  
  @HiveField(2)
  final int sortOrder;

  FavoriteModel({
    required this.serviceId,
    required this.addedAt,
    this.sortOrder = 0,
  });

  FavoriteModel copyWith({
    String? serviceId,
    DateTime? addedAt,
    int? sortOrder,
  }) {
    return FavoriteModel(
      serviceId: serviceId ?? this.serviceId,
      addedAt: addedAt ?? this.addedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}