# Developer Guide for markdownr

This document provides guidelines for agentic coding agents working on this repository.

## Project Overview

markdownr is a Flutter Android app that converts URLs to Markdown format and allows sharing to other apps. It uses the readability algorithm to extract content from web pages.

## Tech Stack

- **Flutter**: 3.32Android only.0+ ()
- **Dart**: 3.0.0+
- **Key dependencies**: http, html2md, flutter_markdown_plus, share_plus, receive_sharing_intent, readability
- **Testing**: flutter_test, mockito, build_runner
- **Linting**: flutter_lints

## Build / Lint / Test Commands

### Running Tests

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/converter_test.dart

# Run a specific test by name
flutter test --name "convert should handle exceptions"
```

### Linting & Formatting

```bash
# Format code (required before committing)
dart format --set-exit-if-changed .

# Run static analysis
flutter analyze
```

### Building

```bash
# Build debug APK
flutter build apk

# Build release APK
flutter build apk --release

# Get dependencies
flutter pub get
```

### Code Generation

```bash
# Generate mock classes (required after modifying mocks)
dart run build_runner build
```

### Taskfile Commands

The project includes a Taskfile.yaml with common tasks:

```bash
# Run tests
task test

# Run lint and format checks
task lint

# Generate mocks
task build-mocks
```

## Code Style Guidelines

### General Conventions

- Follow Flutter/Dart best practices
- Use `analysis_options.yaml` which includes `package:flutter_lints/flutter.yaml`
- Enable strict null safety (Dart 3.0+)
- Prefer immutability: use `const` constructors where possible

### Imports

Organize imports in the following order:
1. Dart core libraries (`dart:io`, `dart:async`, etc.)
2. Package imports (`package:flutter/...`)
3. Relative imports (`package:markdownr/...`)

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdownr/converter.dart';
import 'package:markdownr/settings.dart';
```

### Naming Conventions

- **Classes**: PascalCase (`Url2MdConverter`, `HomePage`)
- **Functions/Methods**: camelCase (`convertPage`, `_buildAppBar`)
- **Private members**: prefix with underscore (`_httpClient`, `_controller`)
- **Constants**: camelCase or SCREAMING_SNAKE_CASE depending on context
- **Files**: snake_case (`converter_test.dart`, `httpclient.dart`)

### Class Structure

```dart
class MyClass {
  // Final fields first
  final String _someField;

  // Constructor
  MyClass({required String someField}) : _someField = someField;

  // Public methods
  Future<void> doSomething() async { }

  // Private methods
  void _helperMethod() { }
}
```

### Error Handling

- Use try-catch blocks for operations that may fail
- Show user-friendly error messages via notification service
- Return sensible defaults on error (see `converter.dart:66-75`)

```dart
try {
  var html = await _httpClient.getPage(url);
  // process...
} catch (e) {
  _notificationService.showToast("$e");
  return defaultValue;
}
```

### Testing Conventions

- Test files: `test/<feature>_test.dart`
- Use mockito for mocking dependencies
- Generate mocks with `@GenerateNiceMocks` annotation
- Run `dart run build_runner build` after creating/updating mocks
- Group tests with `group()` and use `test()` for individual cases

```dart
@GenerateNiceMocks([
  MockSpec<HttpClient>(),
  MockSpec<NotificationService>(),
])
import 'my_test.mocks.dart';

void main() {
  group('MyClass', () {
    late MockHttpClient mockHttpClient;
    late MyClass myClass;

    setUp(() {
      mockHttpClient = MockHttpClient();
      myClass = MyClass(httpClient: mockHttpClient);
    });

    test('should do something', () async {
      when(mockHttpClient.getPage(any)).thenAnswer((_) async => 'result');
      final result = await myClass.doSomething();
      expect(result, 'expected');
    });
  });
}
```

### Flutter-Specific Guidelines

- Use `const` for widgets and constructors when possible
- Follow Flutter's widget composition patterns
- Use `setState` for local state management (simple app)
- Handle async operations in `initState` properly
- Check `context.mounted` before using context in async callbacks

```dart
// Good: Check mounted before using context
Future.delayed(Duration.zero, () {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
});
```

### Widget Build Methods

- Extract UI parts into private methods starting with `_build`
- Keep `build()` method clean and readable
- Use descriptive names: `_buildAppBar()`, `_buildUrlInput()`

## Project Structure

- `lib`: contains the flutter code of the app
- `test`: contains the tests

## CI/CD

The project uses GitHub Actions to build, test and publish the application.

## Common Issues & Solutions

1. **Mocks not found**: Run `dart run build_runner build` to regenerate mocks
2. **Lint errors**: Run `dart format . && flutter analyze` before committing
3. **Missing dependencies**: Run `flutter pub get` after updating pubspec.yaml
