import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../data/models/service_model.dart';
import '../providers/services_provider.dart';
import '../widgets/service_card.dart';
import '../widgets/service_shimmer.dart';
import 'service_detail_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(servicesNotifierProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _handleScroll() {
    if (_tabController.index == 0 && 
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    final notifier = ref.read(servicesNotifierProvider.notifier);
    if (!notifier.hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    await notifier.loadMore();
    
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleSearch(String query) async {
    ref.read(searchQueryProvider.notifier).state = query;
    await ref.read(servicesNotifierProvider.notifier).loadInitial(
      searchQuery: query.isEmpty ? null : query,
    );
  }

  void _navigateToDetail(ServiceModel service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(service: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                ),
                title: const Text(
                  'Services Hub',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Container(
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search services...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _handleSearch('');
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: _handleSearch,
                        ),
                      ),
                      TabBar(
                        controller: _tabController,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(
                            text: 'All Services',
                            icon: Icon(Icons.apps, size: 20),
                          ),
                          Tab(
                            text: 'Favorites',
                            icon: Icon(Icons.favorite, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllServicesTab(),
            _buildFavoritesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllServicesTab() {
    final servicesState = ref.watch(servicesNotifierProvider);
    
    return servicesState.when(
      data: (services) {
        if (services.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No services found',
            subtitle: 'Try adjusting your search or check back later',
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(servicesNotifierProvider.notifier).refresh();
          },
          child: CustomScrollView(
            controller: _scrollController,
            cacheExtent: AppConfig.listItemCacheExtent,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < services.length) {
                      final service = services[index];
                      return ServiceCard(
                        key: ValueKey(service.id),
                        service: service,
                        onTap: () => _navigateToDetail(service),
                      );
                    } else if (_isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return null;
                  },
                  childCount: services.length + (_isLoadingMore ? 1 : 0),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const ServiceShimmer(),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildFavoritesTab() {
    final favoritesAsync = ref.watch(favoriteServicesProvider);
    
    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            subtitle: 'Start adding services to your favorites',
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(favoriteServicesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final service = favorites[index];
              return ServiceCard(
                key: ValueKey('favorite_${service.id}'),
                service: service,
                onTap: () => _navigateToDetail(service),
              );
            },
          ),
        );
      },
      loading: () => ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => const ServiceShimmer(),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_tabController.index == 0) {
                  ref.read(servicesNotifierProvider.notifier).refresh();
                } else {
                  ref.invalidate(favoriteServicesProvider);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}