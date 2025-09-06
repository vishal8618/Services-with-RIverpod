import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services_proj/data/models/service_model.dart';
import 'package:services_proj/data/repositories/services_repository.dart';
import 'package:services_proj/presentation/providers/services_provider.dart';
import 'package:services_proj/presentation/screens/services_screen.dart';
import 'package:services_proj/presentation/widgets/service_card.dart';

class MockServicesRepository extends Mock implements ServicesRepository {}

void main() {
  late MockServicesRepository mockRepository;

  setUp(() {
    mockRepository = MockServicesRepository();
  });

  final testService = ServiceModel(
    id: 'test_1',
    name: 'Test Service',
    description: 'A test service description',
    category: 'Technology',
    price: 99.99,
    imageUrl: 'https://test.com/image.jpg',
    rating: 4.5,
    reviewCount: 100,
    tags: ['professional', 'reliable'],
    isAvailable: true,
    createdAt: DateTime.now(),
    metadata: {'duration': '60 min'},
  );

  group('ServiceCard Widget Tests', () {
    testWidgets('displays service information correctly', (tester) async {
      when(() => mockRepository.isFavorite(any())).thenReturn(false);
      when(() => mockRepository.watchFavoriteIds()).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServiceCard(service: testService),
            ),
          ),
        ),
      );

      expect(find.text('Test Service'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('\$99.99'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(100 reviews)'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('toggles favorite state when heart icon is tapped', 
        (tester) async {
      bool isFavorite = false;
      
      when(() => mockRepository.isFavorite(any())).thenAnswer((_) => isFavorite);
      when(() => mockRepository.toggleFavorite(any())).thenAnswer((_) async {
        isFavorite = !isFavorite;
      });
      when(() => mockRepository.watchFavoriteIds()).thenAnswer(
        (_) => Stream.value(isFavorite ? ['test_1'] : []),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServiceCard(service: testService),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      
      verify(() => mockRepository.toggleFavorite('test_1')).called(1);
    });

    testWidgets('shows unavailable badge when service is not available', 
        (tester) async {
      final unavailableService = testService.copyWith(isAvailable: false);
      
      when(() => mockRepository.isFavorite(any())).thenReturn(false);
      when(() => mockRepository.watchFavoriteIds()).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServiceCard(service: unavailableService),
            ),
          ),
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
    });
  });

  group('ServicesScreen Widget Tests', () {
    testWidgets('displays tabs correctly', (tester) async {
      when(() => mockRepository.getServices(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        category: any(named: 'category'),
        searchQuery: any(named: 'searchQuery'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => [testService]);
      
      when(() => mockRepository.getFavoriteServices()).thenAnswer(
        (_) async => [],
      );
      
      when(() => mockRepository.watchFavoriteIds()).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: ServicesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('All Services'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Services Hub'), findsOneWidget);
    });

    testWidgets('search field filters services', (tester) async {
      when(() => mockRepository.getServices(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        category: any(named: 'category'),
        searchQuery: any(named: 'searchQuery'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => [testService]);
      
      when(() => mockRepository.watchFavoriteIds()).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: ServicesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      
      verify(() => mockRepository.getServices(
        page: 1,
        limit: 20,
        searchQuery: 'test query',
        forceRefresh: false,
      )).called(greaterThanOrEqualTo(1));
    });

    testWidgets('shows empty state when no favorites exist', (tester) async {
      when(() => mockRepository.getServices(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        category: any(named: 'category'),
        searchQuery: any(named: 'searchQuery'),
        forceRefresh: any(named: 'forceRefresh'),
      )).thenAnswer((_) async => [testService]);
      
      when(() => mockRepository.getFavoriteServices()).thenAnswer(
        (_) async => [],
      );
      
      when(() => mockRepository.watchFavoriteIds()).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: ServicesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.text('Start adding services to your favorites'), findsOneWidget);
    });
  });
}
