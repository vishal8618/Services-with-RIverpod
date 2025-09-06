import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../models/favorite_model.dart';
import '../../models/service_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  
  DatabaseService._();
  
  late Box<FavoriteModel> _favoritesBox;
  late Box<ServiceModel> _servicesCache;
  
  Box<FavoriteModel> get favoritesBox => _favoritesBox;
  Box<ServiceModel> get servicesCache => _servicesCache;
  
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    _registerAdapters();
    
    _favoritesBox = await Hive.openBox<FavoriteModel>(AppConfig.favoritesBox);
    _servicesCache = await Hive.openBox<ServiceModel>('services_cache');
    
    await _cleanupOldCache();
  }
  
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ServiceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FavoriteModelAdapter());
    }
  }
  
  Future<void> _cleanupOldCache() async {
    final now = DateTime.now();
    final keysToRemove = <dynamic>[];
    
    for (final key in _servicesCache.keys) {
      final service = _servicesCache.get(key);
      if (service != null) {
        final age = now.difference(service.createdAt);
        if (age > AppConfig.cacheExpiry) {
          keysToRemove.add(key);
        }
      }
    }
    
    if (keysToRemove.isNotEmpty) {
      await _servicesCache.deleteAll(keysToRemove);
      debugPrint('Cleaned up ${keysToRemove.length} expired cache entries');
    }
  }
  
  Future<void> toggleFavorite(String serviceId) async {
    final existingIndex = _favoritesBox.values
        .toList()
        .indexWhere((fav) => fav.serviceId == serviceId);
    
    if (existingIndex != -1) {
      await _favoritesBox.deleteAt(existingIndex);
    } else {
      final favorite = FavoriteModel(
        serviceId: serviceId,
        addedAt: DateTime.now(),
        sortOrder: _favoritesBox.length,
      );
      await _favoritesBox.add(favorite);
    }
  }
  
  bool isFavorite(String serviceId) {
    return _favoritesBox.values.any((fav) => fav.serviceId == serviceId);
  }
  
  List<String> getFavoriteIds() {
    return _favoritesBox.values
        .map((fav) => fav.serviceId)
        .toList();
  }
  
  Stream<List<String>> watchFavoriteIds() {
    return _favoritesBox.watch().map((_) => getFavoriteIds());
  }
  
  Future<void> cacheServices(List<ServiceModel> services) async {
    final cacheMap = <String, ServiceModel>{};
    for (final service in services) {
      cacheMap[service.id] = service;
    }
    await _servicesCache.putAll(cacheMap);
    
    if (_servicesCache.length > AppConfig.maxCacheSize) {
      final sortedKeys = _servicesCache.keys.toList()
        ..sort((a, b) {
          final serviceA = _servicesCache.get(a);
          final serviceB = _servicesCache.get(b);
          if (serviceA == null || serviceB == null) return 0;
          return serviceA.createdAt.compareTo(serviceB.createdAt);
        });
      
      final keysToDelete = sortedKeys.take(
        _servicesCache.length - AppConfig.maxCacheSize
      ).toList();
      
      await _servicesCache.deleteAll(keysToDelete);
    }
  }
  
  ServiceModel? getCachedService(String id) {
    return _servicesCache.get(id);
  }
  
  List<ServiceModel> getCachedServices() {
    return _servicesCache.values.toList();
  }
  
  Future<void> clearCache() async {
    await _servicesCache.clear();
  }
  
  Future<void> clearFavorites() async {
    await _favoritesBox.clear();
  }
  
  Future<void> dispose() async {
    await _favoritesBox.close();
    await _servicesCache.close();
  }
}