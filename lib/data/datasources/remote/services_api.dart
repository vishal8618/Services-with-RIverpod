import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../models/service_model.dart';
import 'api_client.dart';

abstract class ServicesApi {
  Future<List<ServiceModel>> fetchServices({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
  });
  
  Future<ServiceModel> getServiceById(String id);
}

class ServicesApiImpl implements ServicesApi {
  final ApiClient _apiClient;
  
  ServicesApiImpl(this._apiClient);
  
  @override
  Future<List<ServiceModel>> fetchServices({
    int page = 1,
    int limit = 20,
    String? category,
    String? searchQuery,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        AppConfig.servicesEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (category != null) 'category': category,
          if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        },
      );
      
      final List<dynamic> data = response.data?['data'] ?? _getMockServices();
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.unknown) {
        return _getMockServices().map((json) => ServiceModel.fromJson(json)).toList();
      }
      throw _handleError(e);
    }
  }
  
  @override
  Future<ServiceModel> getServiceById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${AppConfig.servicesEndpoint}/$id',
      );
      
      return ServiceModel.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'An error occurred';
        return Exception('Error $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      default:
        return Exception('Network error. Please try again.');
    }
  }
  
  List<Map<String, dynamic>> _getMockServices() {
    return List.generate(50, (index) => {
      'id': 'service_${index + 1}',
      'name': 'Premium Service ${index + 1}',
      'description': 'Experience our top-tier ${_getServiceType(index)} service with exceptional quality and professional expertise. Our dedicated team ensures your complete satisfaction.',
      'category': _getCategory(index),
      'price': 49.99 + (index * 10),
      'imageUrl': 'https://picsum.photos/400/300?random=$index',
      'rating': 4.0 + (index % 10) / 10,
      'reviewCount': 100 + index * 5,
      'tags': _getTags(index),
      'isAvailable': index % 5 != 0,
      'createdAt': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      'providerId': 'provider_${(index % 10) + 1}',
      'metadata': {
        'duration': '${30 + (index % 4) * 15} min',
        'expertise': _getExpertiseLevel(index),
        'bookings': 50 + index * 2,
      },
    });
  }
  
  String _getServiceType(int index) {
    final types = ['consulting', 'development', 'design', 'marketing', 'support'];
    return types[index % types.length];
  }
  
  String _getCategory(int index) {
    final categories = ['Technology', 'Business', 'Creative', 'Health', 'Education'];
    return categories[index % categories.length];
  }
  
  List<String> _getTags(int index) {
    final allTags = [
      ['professional', 'certified', 'experienced'],
      ['innovative', 'modern', 'cutting-edge'],
      ['reliable', 'trusted', 'guaranteed'],
      ['premium', 'exclusive', 'vip'],
      ['fast', 'efficient', 'responsive'],
    ];
    return allTags[index % allTags.length];
  }
  
  String _getExpertiseLevel(int index) {
    final levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert', 'Master'];
    return levels[index % levels.length];
  }
}