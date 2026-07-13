# Contributing to Flutter Foundation App

Thank you for your interest in contributing! 🎉

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/yourusername/flutter_test_app/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots (if applicable)
   - Flutter version and platform

### Suggesting Features

1. Check [Discussions](https://github.com/yourusername/flutter_test_app/discussions) for similar ideas
2. Create a new discussion with:
   - Clear use case
   - Proposed solution
   - Alternative approaches considered

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes following our [Code Style](#code-style)
4. Test your changes thoroughly
5. Commit with clear messages: `git commit -m "Add: feature description"`
6. Push to your fork: `git push origin feature/your-feature`
7. Open a Pull Request with:
   - Description of changes
   - Related issue number (if applicable)
   - Screenshots/videos (for UI changes)

## Code Style

### Dart/Flutter

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` before committing
- Format code with `dart format .`
- Use meaningful variable names
- Add comments for complex logic

### Widget Guidelines

- Make widgets reusable and configurable
- Use `const` constructors when possible
- Follow the existing widget structure in `lib/widgets/`
- Include preview widgets for testing

### Theme & Colors

- Use design tokens from `ThemeColors.get()`
- Never hardcode colors
- Support both light and dark modes
- Follow naming convention: `{category}/{variant}/{intensity}`

### Localization

### Localization

- Add translations to `localization.json`
- Run `dart run tool/generate_arb.dart` to update ARB files
- Use descriptive keys
- Test with all supported languages

## 🛠️ Development Tools

### Widget Previews
We use standalone `preview_*.dart` entrypoints for UI component development and testing, plus a local Flutter Web preview host for Widget V3.
- **Standalone preview:** `flutter run -t lib/widgets/<folder>/preview_<name>.dart -d <device>`
- **Widget V3 web preview host:** `./scripts/serve-v3-preview.sh` regenerates the preview registry, builds/serves `lib/preview_v3/main.dart`, and prints the exact preview URL once ready. Preview files follow `lib/widgets/v3/**/preview_v3_*.dart`; never hand-edit `lib/preview_v3/preview_registry.g.dart`.

### Code Generation
- **Localization:** `dart run tool/generate_arb.dart` then `flutter gen-l10n`

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## Commit Message Format

```
Type: Brief description

Detailed explanation (optional)

Fixes #issue_number (if applicable)
```

**Types:**
- `Add:` New feature or component
- `Fix:` Bug fix
- `Update:` Update existing feature
- `Refactor:` Code refactoring
- `Docs:` Documentation changes
- `Style:` Code style changes
- `Test:` Add or update tests

## Questions?

Feel free to ask in [Discussions](https://github.com/yourusername/flutter_test_app/discussions) or open an issue.

Thank you for contributing! 🙏
