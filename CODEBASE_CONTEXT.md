# Flutter Foundation App - Codebase Context

## 📋 ภาพรวมโปรเจค

**ชื่อโปรเจค:** mcp_test_app (Wi Wallet Flutter Widget 2.0)  
**เวอร์ชัน:** 25.0.5+1  
**Flutter SDK:** ^3.7.2  
**ประเภท:** Multi-platform Flutter Application (iOS, Android, Web, macOS, Linux, Windows)  
**Repository:** https://github.com/nengniwatyah/Wi_Wallet_Flutter_Widget_2.0

## 🎯 จุดประสงค์

Flutter design-system/widget-library repository พร้อม Widgetbook previews, standalone preview entrypoints, localization generation, design tokens, และ reusable UI components สำหรับแอปพลิเคชันทางการเงิน

https://docs.flutter.dev/ui/internationalization
https://docs.flutter.dev/cookbook/design/themes
https://docs.flutter.dev/release/breaking-changes/material-3-migration
https://docs.flutter.dev/ui/advanced/material-3

## 📁 โครงสร้างโปรเจค

```
lib/
├── assets/
│   ├── hugeicons/          # Icon library
│   ├── images/             # SVG/PNG assets
│   └── lottie/             # Lottie assets
├── config/
│   └── themes/
│       ├── theme_color.dart      # Design tokens (100+ colors)
│       ├── base_theme.dart       # ColorScheme definitions
│       └── theme_constants.dart  # Theme constants
├── generated/
│   └── intl/               # Generated localization files
├── l10n/
│   ├── localization.json   # Editable localization source of truth
│   ├── app_en.arb          # English translations
│   ├── app_th.arb          # Thai translations
│   ├── app_zh.arb          # Chinese translations
│   ├── app_ru.arb          # Russian translations
│   └── app_my.arb          # Myanmar translations
├── providers/
│   ├── locale_provider.dart
│   └── theme_provider.dart
├── widgets/
│   ├── announce/
│   ├── avatar/
│   ├── button/
│   ├── card/
│   ├── drawer/
│   ├── image_carousel/
│   ├── input/
│   ├── item_list/
│   ├── loading/
│   ├── navigator_bar/
│   ├── receipt/
│   ├── shortcut_menu/
│   ├── skeleton/
│   ├── snack_bar/
│   ├── tab/
│   └── visa/
├── widgetbook.dart
├── widgetbook_use_cases.dart
├── widgetbook.directories.g.dart
└── main.dart
```

## 🔧 Dependencies หลัก

### UI & Design
- `flutter_svg: ^2.0.9` - SVG icons และ assets
- `google_fonts: ^6.1.0` - Multi-language font support (Noto Sans Thai)
- `hugeicons: ^0.0.9` - Icon library
- `cupertino_icons: ^1.0.8` - iOS style icons

### State Management
- `provider: ^6.1.1` - State management solution

### Localization
- `flutter_localizations` - Flutter localization support
- `intl: ^0.20.2` - Internationalization

### Development & Utilities
- `flutter_lints: ^5.0.0` - Linting rules
- `flutter_gen` - Code generation
- `logging: ^1.2.0` - Logging utilities

## 🌍 Localization (i18n)

### ภาษาที่รองรับ (5 ภาษา)
- 🇬🇧 English (en) - Template language
- 🇹🇭 ไทย (th) - Noto Sans Thai font
- 🇨🇳 中文 (zh) - Chinese Simplified
- 🇷🇺 Русский (ru) - Russian
- 🇲🇲 မြန်မာ (my) - Myanmar

### การตั้งค่า
- **Source of Truth:** `lib/l10n/localization.json`
- **Generation Script:** `tool/generate_arb.dart`
- **ARB files:** `lib/l10n/app_{locale}.arb` (Generated)
- **Generated files:** `lib/generated/intl/`
- **Configuration:** `l10n.yaml` (root level)
- **Font handling:** GoogleFonts.notoSansThai() สำหรับภาษาไทย

### Runtime Language Switching
- LocaleProvider class สำหรับจัดการ locale switching
- Consumer pattern สำหรับ reactive UI updates

## 🎨 Theme System

### Design Token Architecture
**Naming Convention:** `{category}/{variant}/{intensity}`

**Categories:**
- `fill/` - Background colors
- `text/` - Text colors  
- `stroke/` - Border colors
- `primary/` - Primary brand colors
- `success/`, `danger/`, `warning/`, `info/` - Semantic colors

**Variants:**
- `base` - Base colors
- `contrast` - Contrast colors
- `alt` - Alternative colors

**Intensity:** 100-600 (100=lightest, 600=darkest)

### Color Scheme
**Light Mode:**
- Primary: `#FFC23D` (Yellow/Gold)
- Background: `#F5F5F5`
- Surface: `#FFFFFF`
- Text: `#0F0F0F`

**Dark Mode:**
- Primary: `#F2C564` (Yellow/Gold)
- Background: `#1A1A1A`
- Surface: `#242424`
- Text: `#FFFFFF`

### Theme Management
- **ThemeProvider:** จัดการ ThemeMode (light/dark)
- **ThemeColors.get():** Type-safe color access
- **Material Design 3:** useMaterial3: true

## 🧩 Widget Components

### 1. Input Components
- **FullAmountInput** - Amount input with validation, decimal support
- **MobileCodeInput** - Country code + phone number input
- **SearchInput** - Search input with icon

### 2. Navigation Components
- **NavigatorBar** - Bottom navigation with 5 items + floating scan button + 10px blur effect

### 3. Card / Receipt Components
- **VisaCard** - Gradient visa card display with balance
- **CardReviewTransaction** - Transaction review card with details
- **ReceiptComponent** - Transaction receipt component
- **ReceiptImageComponent** - Shareable receipt image layout

### 4. Announcement Components
- **AnnouncementStack** - Animated announcement cards with rotation
- **AnnouncementWarning** - Static warning alert with custom styling
- **AnnouncementDanger** - Static danger/error alert variant

### 5. Drawer Components
- **DrawerReviewTransaction** - Transaction review bottom sheet (75% height)
- **DrawerBalanceDetail** - Balance breakdown drawer with hold amount
- **DrawerDepositChannel** - Bank selection drawer (50% height)
- **DrawerCountryCode** - Country code selector drawer

### 6. Button Components
- **Buttons** - Reusable button component with 3 types (primary, secondary, amount)

### 7. Menu Components
- **ShortcutMenuItem** - Menu item with SVG icon manipulation and theme awareness
- **ItemList** - Versatile list item for menus and transactions

### 8. Display Components
- **Avatar** - Profile card with status badge and skeleton loading
- **ImageCarousel** - Image slider with auto-play support
- **SnackBarWidget** - Custom styled notification snackbar

### 9. Loading Components
- **PreLoading** - Full-screen loading overlay with blur and Lottie
- **LottieSkeleton** - Skeleton loading wrapper using Lottie animation

### 10. Tab Components
- **HorizontalTabs** - Segmented tab switcher for 2-tab and 3-tab content grouping

## 🏗️ Architecture Patterns

### State Management
- **Provider Pattern** - ThemeProvider, LocaleProvider
- **StatelessWidget** - UI components without state
- **StatefulWidget** - Components with animation/state

### Code Organization
```
widgets/{feature}/
├── {widget}.dart              # Main widget
├── preview_{widget}.dart      # Standalone preview/testing widget
└── {WIDGET}_GUIDE.md         # Documentation (or *_CONTEXT.md / *_spec.md)
```

### Widget Features
- **Theme-aware** - ทุก widget รองรับ light/dark mode
- **Responsive** - MediaQuery สำหรับ responsive design
- **Localized** - รองรับ multi-language
- **Reusable** - Self-contained components
- **Previewable** - ตรวจสอบได้ผ่าน Widgetbook หรือ standalone preview

## 🧪 Development Workflows

### Widgetbook
- Entry point: `lib/widgetbook.dart`
- Manual use cases: `lib/widgetbook_use_cases.dart`
- Generated directories: `lib/widgetbook.directories.g.dart`

### Standalone Preview
- Widgets จำนวนมากมี `preview_*.dart` สำหรับรันตรงด้วย `flutter run -t ...`

### Localization Generation
- Edit `lib/l10n/localization.json`
- Run `dart run tool/generate_arb.dart`
- Run `flutter gen-l10n`

### Documentation Schema Generation
- Root schema output: `docs/schema.json`
- Inputs:
  - `CODEBASE_CONTEXT.md`
  - `WIDGETS_GUIDE.md`
  - widget-local markdown under `lib/widgets/`
- Command: `npm run generate-schema`

## 📱 Platform Support

### Configured Platforms (6)
- ✅ iOS (Xcode project configured)
- ✅ Android (Gradle project configured)
- ✅ Web (PWA ready)
- ✅ macOS (Native app)
- ✅ Linux (Native app)
- ✅ Windows (Native app)

## 🔍 Code Quality & Best Practices

### Linting & Standards
- **flutter_lints: ^5.0.0** - Recommended lints
- **analysis_options.yaml** - Linting configuration
- **Material Design 3** compliance

### Implemented Best Practices
- ✅ Type-safe design tokens
- ✅ Theme-aware components
- ✅ Responsive design patterns
- ✅ Localization support
- ✅ SVG asset optimization
- ✅ Provider state management
- ✅ Component documentation

## 🎯 Key Features

### 1. Multi-language Support
- 5 languages with proper font handling
- Runtime language switching
- ARB-based localization system

### 2. Complete Theme System
- 100+ design tokens
- Light/dark mode support
- Type-safe color access

### 3. Production-ready Components
- Financial app focused widgets
- Consistent design patterns
- Comprehensive documentation

### 4. Developer Experience
- Preview widgets for testing
- External device testing support
- Step-by-step setup guides

## 🚀 Recent Updates & Enhancements

### Drawer Components Enhancement
- **Overlay Style Implementation** - Figma-compliant overlay (rgba(0,0,0,0.5) + 10px blur)
- **Static Show Methods** - Consistent `.show()` pattern across all drawer widgets
- **Dismiss Behavior** - Button-only dismiss for security (isDismissible: false)

### Component Organization
- **Folder Structure** - Organized by feature (announce/, card/, drawer/, etc.)
- **Documentation** - Comprehensive guides for each component
- **Preview System** - Individual preview widgets for testing

### External Device Testing
- **Web Server Support** - Test widgets on real devices over local network
- **Multi-device Testing** - Simultaneous testing across devices
- **Real Interaction Testing** - Touch, swipe, scroll behaviors

### Card & Announcement Widgets
- **CardReviewTransaction** - Added API data handling, number formatting, and improved localization support
- **AnnouncementStack** - Refactored to separate base widget from preview, added skeleton loading support

### Widgetbook Integration
- **Centralized Preview** - All widgets cataloged in Widgetbook
- **Interactive Controls** - Knobs and controls for testing widget states
- **Use Case Driven** - Organized by use cases for easy discovery

## ⚠️ Known Issues & Solutions

### Resolved Issues
- ✅ **RenderFlex Overflow** - Fixed with SingleChildScrollView
- ✅ **Null Check Operator** - Removed AppLocalizations dependencies in preview widgets
- ✅ **Import Issues** - Cleaned unused imports

### Current Limitations
- ❌ Navigation routing system
- ❌ API integration layer
- ❌ Local storage implementation
- ❌ Authentication system
- ❌ Unit/Integration tests

## 📊 Project Statistics

- **Total Components:** 20 widgets
- **Supported Languages:** 5 languages
- **Design Tokens:** 100+ color tokens (including alt/ variant)
- **Platform Support:** 6 platforms
- **Dependencies:** 8 main packages
- **Documentation Files:** 18+ guide files
- **Compliance Scores:** Button (85/100), ShortcutMenu (70/100)

## 🔧 Development Workflow

### Setup Commands
```bash
flutter pub get                 # Install dependencies
dart run tool/generate_arb.dart # Generate ARB from JSON
flutter gen-l10n               # Generate localization
flutter run                    # Run main app
flutter test                   # Run tests
```

### Preview Testing
```bash
# Individual widget preview
flutter run lib/widgets/{category}/preview_{widget}.dart

# External device testing
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8000 -t lib/widgets/{category}/preview_{widget}.dart
```

## 📝 Naming Conventions

### Files & Directories
- `snake_case.dart` - Dart files
- `preview_{widget}.dart` - Preview widgets
- `{WIDGET}_GUIDE.md` - Documentation files

### Code Conventions
- `PascalCase` - Class names
- `camelCase` - Variables and methods
- `kebab-case.svg` - Asset files

## 🎯 Future Roadmap

### Planned Enhancements
1. **Navigation System** - Implement go_router
2. **API Layer** - Repository pattern implementation
3. **Testing Suite** - Unit and widget tests
4. **Performance** - Image caching and optimization
5. **Accessibility** - Enhanced a11y support

### Component Expansion
- Form validation widgets
- Chart/graph components
- Advanced animation widgets
- Camera/media components

---

**Last Updated:** November 2025  
**Maintained By:** Wi Wallet Development Team  
**Contact:** niwat.yah@wipay.co.th

---

**Made with ❤️ for the Flutter community**
