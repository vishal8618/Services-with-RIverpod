import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class ServiceModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String category;
  
  @HiveField(4)
  final double price;
  
  @HiveField(5)
  final String imageUrl;
  
  @HiveField(6)
  final double rating;
  
  @HiveField(7)
  final int reviewCount;
  
  @HiveField(8)
  final List<String> tags;
  
  @HiveField(9)
  final bool isAvailable;
  
  @HiveField(10)
  final DateTime createdAt;
  
  @HiveField(11)
  final String? providerId;
  
  @HiveField(12)
  final Map<String, dynamic>? metadata;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.isAvailable,
    required this.createdAt,
    this.providerId,
    this.metadata,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => 
      _$ServiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceModelToJson(this);

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    bool? isAvailable,
    DateTime? createdAt,
    String? providerId,
    Map<String, dynamic>? metadata,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      providerId: providerId ?? this.providerId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}