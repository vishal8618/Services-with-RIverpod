import 'package:flutter/foundation.dart';
import '../datasources/local/database_service.dart';
import '../datasources/remote/services_api.dart';
import '../models/service_model.dart';

abstract class ServicesRepository {
  Future<List<ServiceModel>> getServices({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
    bool forceRefresh = false,
  });
  
  Future<ServiceModel?> getServiceById(String id);
  
  Future<List<ServiceModel>> getFavoriteServices();
  
  Future<void> toggleFavorite(String serviceId);
  
  bool isFavorite(String serviceId);
  
  Stream<List<String>> watchFavoriteIds();
  
  Future<void> clearCache();
}

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesApi _servicesApi;
  final DatabaseService _databaseService;
  
  ServicesRepositoryImpl({
    required ServicesApi servicesApi,
    required DatabaseService databaseService,
  })  : _servicesApi = servicesApi,
        _databaseService = databaseService;
  
  @override
  Future<List<ServiceModel>> getServices({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && page == 1 && category == null && searchQuery == null) {
        final cachedServices = _databaseService.getCachedServices();
        if (cachedServices.isNotEmpty) {
          debugPrint('Returning ${cachedServices.length} cached services');
          return cachedServices;
        }
      }
      
      final services = await _servicesApi.fetchServices(
        page: page,
        limit: limit,
        category: category,
        searchQuery: searchQuery,
      );
      
      if (page == 1 && category == null && searchQuery == null) {
        await _databaseService.cacheServices(services);
      }
      
      return services;
    } catch (e) {
      debugPrint('Error fetching services: $e');
      
      if (page == 1) {
        final cachedServices = _databaseService.getCachedServices();
        if (cachedServices.isNotEmpty) {
          return cachedServices;
        }
      }
      
      rethrow;
    }
  }
  
  @override
  Future<ServiceModel?> getServiceById(String id) async {
    try {
      final cachedService = _databaseService.getCachedService(id);
      if (cachedService != null) {
        return cachedService;
      }
      
      final service = await _servicesApi.getServiceById(id);
      await _databaseService.cacheServices([service]);
      return service;
    } catch (e) {
      debugPrint('Error fetching service by id: $e');
      return _databaseService.getCachedService(id);
    }
  }
  
  @override
  Future<List<ServiceModel>> getFavoriteServices() async {
    final favoriteIds = _databaseService.getFavoriteIds();
    final favoriteServices = <ServiceModel>[];
    
    for (final id in favoriteIds) {
      final service = await getServiceById(id);
      if (service != null) {
        favoriteServices.add(service);
      }
    }
    
    return favoriteServices;
  }
  
  @override
  Future<void> toggleFavorite(String serviceId) async {
    await _databaseService.toggleFavorite(serviceId);
  }
  
  @override
  bool isFavorite(String serviceId) {
    return _databaseService.isFavorite(serviceId);
  }
  
  @override
  Stream<List<String>> watchFavoriteIds() {
    return _databaseService.watchFavoriteIds();
  }
  
  @override
  Future<void> clearCache() async {
    await _databaseService.clearCache();
  }
}