import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/services_api.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/services_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final servicesApiProvider = Provider<ServicesApi>((ref) {
  return ServicesApiImpl(ref.watch(apiClientProvider));
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepositoryImpl(
    servicesApi: ref.watch(servicesApiProvider),
    databaseService: ref.watch(databaseServiceProvider),
  );
});

final servicesProvider = FutureProvider.family<List<ServiceModel>, ServicesQueryParams>(
  (ref, params) async {
    final repository = ref.watch(servicesRepositoryProvider);
    return repository.getServices(
      page: params.page,
      limit: params.limit,
      category: params.category,
      searchQuery: params.searchQuery,
      forceRefresh: params.forceRefresh,
    );
  },
);

final favoriteServicesProvider = FutureProvider<List<ServiceModel>>(
  (ref) async {
    ref.watch(favoriteIdsStreamProvider);
    final repository = ref.watch(servicesRepositoryProvider);
    return repository.getFavoriteServices();
  },
);

final filteredFavoriteServicesProvider = Provider<AsyncValue<List<ServiceModel>>>(
  (ref) {
    final favoritesAsync = ref.watch(favoriteServicesProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
    
    return favoritesAsync.when(
      data: (favorites) {
        if (searchQuery.isEmpty) {
          return AsyncValue.data(favorites);
        }
        
        final queryWords = searchQuery.split(' ').where((word) => word.isNotEmpty).toList();
        
        final filtered = favorites.where((service) {
          final name = service.name.toLowerCase();
          final description = service.description.toLowerCase();
          final category = service.category.toLowerCase();
          final tags = service.tags.map((tag) => tag.toLowerCase()).toList();
          final searchText = '$name $description $category ${tags.join(' ')}';
          
          // Match if all query words are found in the combined text
          return queryWords.every((word) => searchText.contains(word));
        }).toList();
        
        return AsyncValue.data(filtered);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

final favoriteIdsStreamProvider = StreamProvider<List<String>>(
  (ref) {
    final repository = ref.watch(servicesRepositoryProvider);
    return repository.watchFavoriteIds();
  },
);

final isFavoriteProvider = Provider.family<bool, String>(
  (ref, serviceId) {
    final favoriteIds = ref.watch(favoriteIdsStreamProvider).value ?? [];
    return favoriteIds.contains(serviceId);
  },
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final currentPageProvider = StateProvider<int>((ref) => 1);

class ServicesQueryParams {
  final int page;
  final int limit;
  final String? category;
  final String? searchQuery;
  final bool forceRefresh;

  const ServicesQueryParams({
    this.page = 1,
    this.limit = 20,
    this.category,
    this.searchQuery,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServicesQueryParams &&
        other.page == page &&
        other.limit == limit &&
        other.category == category &&
        other.searchQuery == searchQuery &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode {
    return Object.hash(page, limit, category, searchQuery, forceRefresh);
  }
}

class ServicesNotifier extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  final Ref ref;
  final List<ServiceModel> _allServices = [];
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentCategory;
  String? _currentSearchQuery;

  ServicesNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> loadInitial({String? category, String? searchQuery, bool forceRefresh = false}) async {
    _currentPage = 1;
    _hasMore = true;
    _currentCategory = category;
    _currentSearchQuery = searchQuery;
    _allServices.clear();
    
    state = const AsyncValue.loading();
    
    try {
      final repository = ref.read(servicesRepositoryProvider);
      final services = await repository.getServices(
        page: _currentPage,
        category: _currentCategory,
        searchQuery: _currentSearchQuery,
        forceRefresh: forceRefresh,
      );
      
      _allServices.addAll(services);
      _hasMore = services.length >= 20;
      state = AsyncValue.data(_allServices);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    
    _currentPage++;
    
    try {
      final repository = ref.read(servicesRepositoryProvider);
      final services = await repository.getServices(
        page: _currentPage,
        category: _currentCategory,
        searchQuery: _currentSearchQuery,
      );
      
      if (services.isEmpty || services.length < 20) {
        _hasMore = false;
      }
      
      if (services.isNotEmpty) {
        _allServices.addAll(services);
        state = AsyncValue.data(List.from(_allServices));
      }
    } catch (error, stack) {
      _currentPage--;
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> refresh() async {
    // Clear cache to force fresh data
    final repository = ref.read(servicesRepositoryProvider);
    await repository.clearCache();
    
    await loadInitial(
      category: _currentCategory,
      searchQuery: _currentSearchQuery,
    );
  }

  bool get hasMore => _hasMore;
}

final servicesNotifierProvider = 
    StateNotifierProvider<ServicesNotifier, AsyncValue<List<ServiceModel>>>(
  (ref) => ServicesNotifier(ref),
);