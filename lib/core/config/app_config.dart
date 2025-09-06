abstract class AppConfig {
  static const String baseUrl = 'https://api.example.com';
  static const String servicesEndpoint = '/services';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  static const int maxCacheSize = 100;
  static const Duration cacheExpiry = Duration(hours: 1);
  
  static const String databaseName = 'services_favorites.db';
  static const String favoritesBox = 'favorites_box';
  
  static const int pageSize = 20;
  static const double listItemCacheExtent = 200.0;
}