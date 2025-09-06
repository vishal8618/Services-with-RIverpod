# Contributing to Services Hub

Thank you for your interest in contributing to Services Hub! This document provides guidelines for contributing to the project.

## Development Setup

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/your-username/services-hub.git
   cd services-hub
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format lib/` before committing
- Run `flutter analyze` to check for issues
- Ensure all tests pass with `flutter test`

## Architecture Guidelines

- Follow the existing clean architecture pattern
- Use Riverpod for state management
- Implement repository pattern for data access
- Write tests for new features
- Keep UI widgets pure and testable

## Submitting Changes

1. Create a feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Add tests for new functionality
4. Run the full test suite
5. Commit with clear, descriptive messages
6. Push to your fork
7. Create a Pull Request

## Pull Request Guidelines

- Provide a clear description of the changes
- Include screenshots for UI changes
- Ensure CI passes
- Update documentation if needed
- Link any related issues

## Reporting Issues

- Use the GitHub issue tracker
- Provide detailed reproduction steps
- Include device/platform information
- Add screenshots or videos if helpful

Thank you for contributing! 🚀