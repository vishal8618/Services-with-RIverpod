import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:services_proj/main.dart' as app;
import 'package:services_proj/data/datasources/local/database_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end Integration Tests', () {
    setUpAll(() async {
      await DatabaseService.instance.initialize();
    });

    tearDown(() async {
      await DatabaseService.instance.clearFavorites();
    });

    testWidgets('Complete user flow - browse, search, and favorite services',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Services Hub'), findsOneWidget);
      expect(find.text('All Services'), findsOneWidget);
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      expect(find.byType(Card), findsWidgets);
      
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      
      await tester.enterText(searchField, 'Premium');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      final firstServiceCard = find.byType(Card).first;
      expect(firstServiceCard, findsOneWidget);
      
      final favoriteButton = find.descendant(
        of: firstServiceCard,
        matching: find.byIcon(Icons.favorite_border),
      );
      
      if (favoriteButton.evaluate().isNotEmpty) {
        await tester.tap(favoriteButton.first);
        await tester.pumpAndSettle();
        
        expect(
          find.descendant(
            of: firstServiceCard,
            matching: find.byIcon(Icons.favorite),
          ),
          findsOneWidget,
        );
      }
      
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      
      final favoritesTab = find.text('Favorites').last;
      await tester.tap(favoritesTab);
      await tester.pumpAndSettle();
    });

    testWidgets('Persistence test - favorites are saved across app restarts',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      final firstServiceCard = find.byType(Card).first;
      final favoriteButton = find.descendant(
        of: firstServiceCard,
        matching: find.byIcon(Icons.favorite_border),
      );
      
      String? serviceId;
      if (favoriteButton.evaluate().isNotEmpty) {
        await tester.tap(favoriteButton.first);
        await tester.pumpAndSettle();
        
        final services = DatabaseService.instance.getFavoriteIds();
        expect(services.isNotEmpty, true);
        serviceId = services.first;
      }
      
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      
      app.main();
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      
      if (serviceId != null) {
        final savedFavorites = DatabaseService.instance.getFavoriteIds();
        expect(savedFavorites.contains(serviceId), true);
      }
    });
  });
}