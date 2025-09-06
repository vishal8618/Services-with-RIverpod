# Services Hub

A Flutter app for browsing and managing favorite services.

## What it does

- Browse services with search
- Save favorites locally 
- Two tabs: All Services and Favorites
- Works offline with cached data

## Features

- Real-time search
- Heart icon to favorite/unfavorite
- Local storage using Hive
- Lazy loading for performance
- Material 3 design
- Dark mode support

## How to run

1. Clone the repo
```bash
git clone <repo-url>
cd services_proj
```

2. Get dependencies
```bash
flutter pub get
```

3. Generate model files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app
```bash
flutter run
```

## Tests

Run widget tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/app_test.dart
```

## Tech Stack

- **Flutter** with Dart
- **Riverpod** for state management
- **Hive** for local database
- **Dio** for API calls
- **Material 3** for UI

## Project Structure

```
lib/
├── core/           # Config and theme
├── data/           # Models, API, database
└── presentation/   # UI screens and widgets
```

## Notes

Currently uses mock data. To connect real API, update the baseUrl in `lib/core/config/app_config.dart`.

The app handles large lists efficiently with pagination and caching.