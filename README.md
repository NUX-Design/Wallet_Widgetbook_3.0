
<img width="1920" height="1080" alt="Cover" src="https://github.com/user-attachments/assets/4e0d1102-da06-4f92-bbfc-20123db01353" />

# Flutter Foundation App 🚀

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-ready Flutter foundation with **multi-language support (i18n)**, **theme system (light/dark mode)**, **design tokens**, and **reusable UI components** for financial applications.

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Foundation Setup](#-foundation-setup)
  - [1. Localization (i18n)](#1-localization-i18n)
  - [2. Theme System](#2-theme-system)
  - [3. Design Tokens](#3-design-tokens)
  - [4. Reusable Widgets](#4-reusable-widgets)
- [Project Structure](#-project-structure)
- [How to Apply to Your Project](#-how-to-apply-to-your-project)
- [Available Components](#-available-components)
- [Preview Widgets on External Devices](#-preview-widgets-on-external-devices)
- [Contributing](#-contributing)

---

## ✨ Features

- 🌍 **Multi-language Support** - 5 languages (EN, TH, ZH, RU, MY) with proper font handling
- 🎨 **Complete Theme System** - Light/Dark mode with 100+ design tokens
- 🧩 **Reusable Components** - Production-ready widgets for financial apps
- 📱 **Multi-platform** - iOS, Android, Web, macOS, Linux, Windows
- 🎯 **Type-safe Design Tokens** - Consistent colors across the app
- ♿ **Responsive Design** - Adapts to different screen sizes

---

## 📱 Platform Compatibility

Widget Library นี้รองรับ platform versions ดังต่อไปนี้:

| Platform | Minimum Version | Notes |
|----------|-----------------|-------|
| **iOS** | 12.0+ | รองรับตั้งแต่ iPhone 5s ขึ้นไป |
| **Android** | API 21 (Android 5.0 Lollipop)+ | ค่า default จาก Flutter SDK |
| **Web** | Modern browsers | Chrome, Firefox, Safari, Edge |
| **macOS** | 10.14+ | Mojave ขึ้นไป |
| **Windows** | Windows 10+ | - |
| **Linux** | Ubuntu 18.04+ | - |

> [!NOTE]
> Flutter ใช้ Skia rendering engine ของตัวเอง ทำให้ widget แสดงผลเหมือนกันในทุก OS version ที่รองรับ หากแอปหลักกำหนด minimum version ที่สูงกว่า (เช่น iOS 16+) widget library นี้จะทำงานได้ปกติโดยไม่มีผลกระทบใดๆ

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK ^3.7.2
- Dart SDK
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

```bash
# Clone the repository
git clone https://github.com/nengniwatyah/Wi_Wallet_Flutter_Widget_2.0.git
cd Wi_Wallet_Flutter_Widget_2.0

# Install dependencies
flutter pub get

# Generate localization files
dart run tool/generate_arb.dart
flutter gen-l10n

# Run the app
flutter run
```

---

## 🏗️ Foundation Setup

### 1. Localization (i18n)

#### Step-by-Step Implementation

**Step 1:** Add dependencies to `pubspec.yaml`

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
  google_fonts: ^6.1.0  # For multi-language font support
```

**Step 2:** Create `l10n.yaml` at project root

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/generated/intl
```

**Step 3:** Update `localization.json` at project root

```json
[
  {
    "Name": "app_name",
    "EN": "My App",
    "TH": "แอปของฉัน",
    "description": "Application name"
  },
  {
    "Name": "home",
    "EN": "Home",
    "TH": "หน้าหลัก"
  },
  {
    "Name": "settings",
    "EN": "Settings",
    "TH": "ตั้งค่า"
  }
]
```

**Step 4:** Generate localization files

```bash
dart run tool/generate_arb.dart
flutter gen-l10n
```

**Step 5:** Setup MaterialApp

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:your_app/generated/intl/app_localizations.dart';

MaterialApp(
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('th'),
    Locale('zh'),
  ],
  // For Thai language, use Noto Sans Thai
  theme: ThemeData(
    textTheme: GoogleFonts.notoSansThaiTextTheme(),
  ),
)
```

**Step 6:** Use in widgets

```dart
Text(AppLocalizations.of(context)!.home)
```

#### Runtime Language Switching

```dart
// Create LocaleProvider
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;
  
  void setLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
}

// Use in MaterialApp
Consumer<LocaleProvider>(
  builder: (context, localeProvider, child) {
    return MaterialApp(
      locale: localeProvider.locale,
      // ... other properties
    );
  },
)

// Change language
Provider.of<LocaleProvider>(context, listen: false)
  .setLocale(Locale('th'));
```

---

### 2. Theme System

#### Step-by-Step Implementation

**Step 1:** Create `lib/config/themes/theme_color.dart`

```dart
import 'package:flutter/material.dart';

class ThemeColors {
  static Color _hex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    else if (hex.length == 8) {
      hex = '${hex.substring(6)}${hex.substring(0, 6)}';
    }
    return Color(int.parse(hex, radix: 16));
  }

  static final Map<String, Color> light = {
    'primary/400': _hex('#FFC23D'),
    'fill/base/100': _hex('#FFFFFF'),
    'fill/base/300': _hex('#F5F5F5'),
    'text/base/600': _hex('#0F0F0F'),
    'stroke/base/100': _hex('#EDEDED'),
    // Add more colors...
  };

  static final Map<String, Color> dark = {
    'primary/400': _hex('#F2C564'),
    'fill/base/100': _hex('#242424'),
    'fill/base/300': _hex('#1A1A1A'),
    'text/base/600': _hex('#FFFFFF'),
    'stroke/base/100': _hex('#383838'),
    // Add more colors...
  };

  static Color get(String theme, String key) {
    if (theme == 'light') {
      return light[key] ?? dark[key] ?? Colors.transparent;
    } else {
      return dark[key] ?? light[key] ?? Colors.transparent;
    }
  }
}
```

**Step 2:** Create ThemeProvider

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
      ? ThemeMode.dark 
      : ThemeMode.light;
    notifyListeners();
  }
}
```

**Step 3:** Setup MaterialApp

```dart
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme(
          primary: ThemeColors.get('light', 'primary/400'),
          surface: ThemeColors.get('light', 'fill/base/100'),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme(
          primary: ThemeColors.get('dark', 'primary/400'),
          surface: ThemeColors.get('dark', 'fill/base/100'),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
    );
  },
)
```

**Step 4:** Use in widgets

```dart
final brightnessKey = Theme.of(context).brightness == Brightness.light 
  ? 'light' 
  : 'dark';

Container(
  color: ThemeColors.get(brightnessKey, 'fill/base/300'),
  child: Text(
    'Hello',
    style: TextStyle(
      color: ThemeColors.get(brightnessKey, 'text/base/600'),
    ),
  ),
)
```

---

### 3. Design Tokens

#### Token Naming Convention

```
Format: {category}/{variant}/{intensity}

Categories:
- fill/      → Background colors
- text/      → Text colors
- stroke/    → Border colors
- primary/   → Primary brand colors
- success/   → Success state colors
- danger/    → Error state colors
- warning/   → Warning state colors
- info/      → Info state colors

Variants:
- base       → Base colors
- contrast   → Contrast colors

Intensity: 100-600 (100=lightest, 600=darkest)

Examples:
- fill/base/300      → Main background
- text/base/600      → Primary text (darkest)
- primary/400        → Primary brand color
- stroke/contrast/600 → Contrast border
```

#### How to Add New Colors

1. Add to `theme_color.dart`:

```dart
static final Map<String, Color> light = {
  // ... existing colors
  'custom/brand/500': _hex('#FF5733'),
};

static final Map<String, Color> dark = {
  // ... existing colors
  'custom/brand/500': _hex('#FF8C66'),
};
```

2. Use in your app:

```dart
ThemeColors.get(brightnessKey, 'custom/brand/500')
```

---

### 4. Reusable Widgets

#### Creating Theme-Aware Widgets

```dart
class ThemedCard extends StatelessWidget {
  final Widget child;
  
  const ThemedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final brightnessKey = Theme.of(context).brightness == Brightness.light 
      ? 'light' 
      : 'dark';
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.get(brightnessKey, 'fill/base/100'),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeColors.get(brightnessKey, 'stroke/base/100'),
        ),
      ),
      child: child,
    );
  }
}
```

---

## 📁 Project Structure

```
lib/
├── assets/
│   ├── hugeicons/          # Icon library
│   └── images/             # SVG icons
├── config/
│   └── themes/
│       ├── theme_color.dart      # Design tokens
│       ├── base_theme.dart       # ColorScheme definitions
│       └── theme_constants.dart  # Theme constants
├── core/
│   ├── providers/          # State management
│   └── utils/              # Utility functions
├── generated/
│   └── intl/               # Generated localization files
├── l10n/
│   ├── app_en.arb          # English translations
│   ├── app_th.arb          # Thai translations
│   ├── app_zh.arb          # Chinese translations
│   ├── app_ru.arb          # Russian translations
│   └── app_my.arb          # Myanmar translations
├── widgets/
│   ├── announce/           # Announcement components
│   ├── card/               # Card components
│   ├── drawer/             # Drawer components
│   ├── navigator_bar/      # Bottom navigation
│   ├── visa/               # Visa card component
│   ├── full_amount_input.dart
│   ├── mobile_code_input.dart
│   ├── search_input.dart
│   └── buttons.dart
└── main.dart
```

---

## 🎯 How to Apply to Your Project

### Option 1: Copy Entire Foundation

1. Copy these folders to your project:
   ```
   lib/config/themes/
   lib/l10n/
   lib/generated/intl/
   ```
2. Copy `l10n.yaml` to your project root
3. Add dependencies to `pubspec.yaml`
4. Run `flutter pub get` and `flutter gen-l10n`

### Option 2: Copy Specific Components

#### Copy Theme System Only
1. Copy `lib/config/themes/theme_color.dart`
2. Create ThemeProvider (see [Theme System](#2-theme-system))
3. Setup MaterialApp with theme configuration

#### Copy Localization Only
1. Copy `lib/l10n/` folder
2. Copy `l10n.yaml`
3. Add dependencies and run `flutter gen-l10n`
4. Setup MaterialApp with localization delegates

#### Copy Individual Widgets
Each widget in `lib/widgets/` is self-contained:
1. Copy the widget file (e.g., `full_amount_input.dart`)
2. Copy required assets (SVG icons)
3. Ensure `ThemeColors` is available
4. Import and use in your app

---

## 🧩 Available Components

### 1. NavigatorBar

Bottom navigation with floating center button.

```dart
NavigatorBar(opacity: 0.9)
```

**Features:**
- 5 menu items
- Floating scan button
- Theme-aware colors
- Localized labels

### 2. FullAmountInput

Amount input with validation.

```dart
FullAmountInput(
  controller: _controller,
  onChanged: (value) => print(value),
  infoText: 'Minimum 100 THB',
)
```

**Features:**
- Decimal number support
- Min/max validation
- Clear button
- Error/success states

### 3. VisaCard

Gradient visa card display.

```dart
VisaCard(
  cardNumber: '1234 5678 9012 3456',
  expiryDate: '12/25',
  balance: 50000.00,
)
```

### 4. AnnouncementStack

Animated announcement cards.

```dart
AnnouncementStack(
  messages: ['Message 1', 'Message 2'],
)
```

**Features:**
- Auto-rotation
- Slide animations
- Dismissible cards

### 5. SearchInput

Search input with icon.

```dart
SearchInput(
  controller: _searchController,
  onChanged: (value) => search(value),
)
```

### 6. MobileCodeInput

Country code + phone number input.

```dart
MobileCodeInput(
  onChanged: (code, number) => print('$code $number'),
)
```

### 7. DrawerReviewTransaction

Bottom sheet drawer for transaction review.

```dart
DrawerReviewTransaction.show(
  context,
  warningTitle: 'Please recheck information',
  warningDescription: 'Cannot be changed once confirmed.',
  totalAmount: '5,000.00',
  // ... other properties
);
```

**Features:**
- Transaction details display
- Warning message
- Confirmation flow
- X button only dismiss (secure)

### 8. DrawerBalanceDetail

Balance breakdown drawer with hold amount details.

```dart
DrawerBalanceDetail.show(
  context,
  totalBalanceAmount: '100,000.00',
  holdAmountValue: '5,030.20',
  ledgerBalanceValue: '15,030.20',
  // ... other properties
);
```

**Features:**
- Balance breakdown display
- Hold amount explanation
- Full-wallet image asset
- Button only dismiss

### 9. DrawerDepositChannel

Bank selection drawer for deposit channels.

```dart
DrawerDepositChannel(
  onBankSelected: (bank) => print('Selected: $bank'),
  onClose: () => Navigator.pop(context),
)
```

**Features:**
- Bank logo display
- Mobile banking options
- Scrollable bank list
- Selection callback

### 10. Avatar

Profile card with status badge and skeleton loading.

```dart
Avatar(
  name: 'Tony Stark',
  handle: '@ironman',
  status: AvatarStatus.warning,
)
```

### 11. ImageCarousel

Image slider with auto-play support.

```dart
ImageCarousel(
  pages: [Image.asset('banner1.png')],
  autoPlay: true,
)
```

### 12. ItemList

Versatile list item for menus and transactions.

```dart
ItemList(
  type: ItemListType.transaction,
  title: 'Payment',
  amount: '-500.00 THB',
)
```

### 13. PreLoading

Full-screen loading overlay with blur effect.

```dart
if (isLoading) const PreLoading()
```

### 14. LottieSkeleton

Skeleton loading wrapper using Lottie.

```dart
LottieSkeleton(
  isLoading: true,
  child: Text('Content'),
)
```

### 15. SnackBarWidget

Custom styled notifications.

```dart
SnackBarWidget.show(
  context,
  title: 'Success',
  type: SnackBarType.success,
);
```

---

## 📱 Preview Widgets with Widgetbook

Widgetbook provides an interactive UI to explore and test your widgets locally and in CI.

### Local Preview

```bash
# Run Widgetbook locally (web)
flutter pub run widgetbook --target lib/widgetbook.dart
# Or, if you have a custom entrypoint:
flutter pub run widgetbook -t lib/widgetbook.dart
```

Open `http://localhost:8080` in your browser to browse the widget catalogue.

### Widgetbook Cloud (CI preview)

The repository includes a GitHub Actions workflow (`.github/workflows/widgetbook.yml`) that builds and publishes a preview to Widgetbook Cloud.

After a successful run you will see a comment on the PR with a link, e.g.:

```
Widgetbook preview: https://preview.widgetbook.io/your-repo/commit/<sha>
```

You can also manually trigger the workflow:

```bash
gh workflow run widgetbook.yml
```

### External Device Preview (Web Server)

You can also serve any preview widget on your local network:

```bash
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8000 -t lib/<path_to_preview_file>.dart
```

Then open `http://<YOUR_IP>:8000` on any device on the same Wi‑Fi.

#### Available Preview Widgets

- Drawer components
  - `preview_drawer_balance_detail.dart`
  - `preview_drawer_review_transaction.dart`
  - `preview_drawer_deposit_channel.dart`
- Card components
  - `preview_card_review_transaction.dart`
- Announcement components
  - `preview_announcement_warning.dart`
- New Widgets
  - `preview_avatar.dart`
  - `preview_image_carousel.dart`
  - `preview_item_list.dart`
  - `preview_pre_loading.dart`
  - `preview_lottie_skeleton.dart`
  - `preview_snack_bar.dart`


---

## 🤖 AI Integration (Wi Wallet MCP)

This project allows you to turn your Design System into a context for AI Developers (Cursor, Claude Desktop, Antigravity, etc.) via **Model Context Protocol (MCP)**.

### 1. Team Installation (Automated) 🚀

We provide a script to automatically register this MCP server in your IDE (Antigravity/Cursor) with the correct absolute paths for your machine.

```bash
cd mcp-server
npm install
npm run install-mcp
```
*Note: Restart your IDE after the script finishes.*

### 2. Auto-generate JSON Schema

Convert `GUIDE.md`, `spec.md`, and project structure into a single `docs/schema.json` file that AI can easily understand.

**Run command:**
```bash
npm run generate-schema
```

**Features:**
*   **Auto-Scan**: Finds all `lib/widgets/**/*.{md,MD}` files (GUIDE, spec, CONTEXT).
*   **Implementation Details**: Automatically extracts localization and theme import paths.
*   **Smart Merge**: Combines data from the main guide and individual files.

### 3. Wi Wallet MCP Server

A local server that feeds the Design System Knowledge to your AI Assistant.

**Capabilities:**
*   **Get Design System Info**: Ask AI about tokens, colors, or project structure.
*   **List/Get Widgets**: Ask AI "What widgets do we have?" or "How to use FullAmountInput?".
*   **Auto-Reload**: The server automatically reloads `schema.json` on every request. You can update docs, run `generate-schema`, and the AI gets the new info immediately!

---

## 📦 Dependencies

```yaml
dependencies:
  flutter_svg: ^2.0.9          # SVG support
  google_fonts: ^6.1.0         # Multi-language fonts
  hugeicons: ^0.0.9            # Icon library
  provider: ^6.1.1             # State management
  intl: ^0.20.2                # Internationalization
  lottie: ^3.1.0               # Animations
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Docs

https://docs.flutter.dev/ui/internationalization
https://docs.flutter.dev/cookbook/design/themes
https://docs.flutter.dev/release/breaking-changes/material-3-migration
https://docs.flutter.dev/ui/advanced/material-3

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Design tokens inspired by modern design systems
- Multi-language support following Flutter best practices
- UI components designed for financial applications

---

## 📞 Support

- 📧 Email: niwat.yah@wipay.co.th
- 🐛 Issues: [GitHub Issues](https://github.com/nengniwatyah/Wi_Wallet_Flutter_Widget_2.0/issues)

---

**Made with ❤️ for the Flutter community**
