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
      
      final List<dynamic> data = response.data?['data'] ?? _getMockServices(
        category: category,
        searchQuery: searchQuery,
        page: page,
        limit: limit,
      );
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.unknown) {
        final mockData = _getMockServices(
          category: category,
          searchQuery: searchQuery,
          page: page,
          limit: limit,
        );
        return mockData.map((json) => ServiceModel.fromJson(json)).toList();
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
  
  List<Map<String, dynamic>> _getMockServices({
    String? category,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) {
    // Generate all services first
    var allServices = List.generate(100, (index) => {
      'id': 'service_${index + 1}',
      'name': _getServiceName(index),
      'description': _getServiceDescription(index),
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

    // Filter by category if provided
    if (category != null && category.isNotEmpty) {
      allServices = allServices.where((service) => 
        service['category'] == category).toList();
    }

    // Filter by search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      final queryWords = query.split(' ').where((word) => word.isNotEmpty).toList();
      
      allServices = allServices.where((service) {
        final name = (service['name'] as String).toLowerCase();
        final description = (service['description'] as String).toLowerCase();
        final category = (service['category'] as String).toLowerCase();
        final tags = (service['tags'] as List<String>).map((tag) => tag.toLowerCase()).toList();
        final searchText = '$name $description $category ${tags.join(' ')}';
        
        // Match if all query words are found in the combined text
        return queryWords.every((word) => searchText.contains(word));
      }).toList();
    }

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    
    if (startIndex >= allServices.length) {
      return [];
    }
    
    return allServices.sublist(
      startIndex, 
      endIndex > allServices.length ? allServices.length : endIndex,
    );
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
  
  String _getServiceName(int index) {
    final serviceNames = [
      'Web Development', 'Mobile App Design', 'Digital Marketing', 'SEO Optimization', 'Content Writing',
      'Logo Design', 'Brand Strategy', 'Social Media Management', 'E-commerce Solutions', 'UI/UX Design',
      'Data Analysis', 'Business Consulting', 'Photography', 'Video Editing', 'Graphic Design',
      'WordPress Development', 'React Development', 'Flutter App Development', 'Node.js Backend', 'Python Automation',
      'Machine Learning', 'Artificial Intelligence', 'Blockchain Development', 'Cybersecurity Audit', 'Cloud Migration',
      'DevOps Consulting', 'Database Design', 'API Development', 'Payment Integration', 'Performance Optimization',
      'Email Marketing', 'Influencer Marketing', 'Market Research', 'Copywriting', 'Translation Services',
      'Voice Over', 'Animation', 'Illustration', 'Icon Design', 'Website Maintenance',
      'Technical Writing', 'Product Management', 'Agile Coaching', 'Quality Assurance', 'Software Testing',
      'Music Production', 'Podcast Editing', 'Audio Mastering', 'Sound Design', 'Legal Consultation',
    ];
    return serviceNames[index % serviceNames.length];
  }
  
  String _getServiceDescription(int index) {
    final serviceName = _getServiceName(index);
    final descriptions = [
      'Professional $serviceName service with expert-level quality and fast delivery.',
      'High-quality $serviceName solutions tailored to your specific business needs.',
      'Experienced $serviceName specialist providing comprehensive and reliable services.',
      'Creative $serviceName with modern approaches and innovative techniques.',
      'Budget-friendly $serviceName services without compromising on quality.',
      'Enterprise-grade $serviceName solutions for businesses of all sizes.',
      'Custom $serviceName services designed to exceed your expectations.',
      'Award-winning $serviceName with proven track record and client satisfaction.',
      'Fast turnaround $serviceName services with 24/7 support availability.',
      'Premium $serviceName consultation with industry best practices.',
    ];
    return descriptions[index % descriptions.length];
  }
}