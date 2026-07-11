# 🚀 Release Notes (Unreleased) - MCP Server Hardening, Cross-Agent Skills & New Widgets

**Release Date:** July 2026
**Branch:** `dev`
**Base Version:** `25.0.5+1` (pubspec version unchanged — no version bump yet)

---

## ✨ What's New

### 🧩 New Widgets
- **Tab (Horizontal Tabs)** - New horizontal tabs widget with Widgetbook registration.
- **Receipt** - New receipt component family with dedicated `receipt/` folder and Figma-sourced skill.
- **Announcement (Danger / Warning / Stack)** - `AnnouncementDanger` widget added; `AnnouncementStack` and `AnnouncementWarning` refactored and registered in Widgetbook.

### 🤖 MCP Server v2.0 & Production Hardening
- **Figma-to-Flutter Tools** - MCP server upgraded to v2.0, adding Figma-to-Flutter conversion and Widgetbook tooling; renamed to `flutter-widget-wallet-mcp`.
- **Phase 1-7 Production Hardening** - Completed a full hardening pass on the MCP server (CI, error handling, stability) plus follow-up fixes for MCP/Flutter CI failures.
- **Phase 8 Hosting Pilot** - Migrated hosting from Koyeb to Render, added a public edge proxy for onboarding, and added support for direct bearer auth on the hosted MCP service.
- **Remote Verification Tooling** - Added `npm run verify:mcp:remote` and related scripts under `mcp-server/scripts/` to validate the deployed remote endpoint.

### 🧠 Cross-Agent Skill Packs
- **Skill Packs for Claude Code, Codex, and Kiro** - Added `skills/claude-code/`, `skills/codex/`, and `skills/kiro/` with 8 shared skills each: `flutter-widget-adapt`, `flutter-widget-audit`, `flutter-widget-beginner`, `flutter-widget-figma-to-code`, `flutter-widget-install`, `flutter-widget-preview`, `flutter-widget-search`, `flutter-widget-upgrade`.
- **Supported Skill Distributions** - Cross-agent distributions are maintained only for the verified native skill layouts under `skills/`; the unverified Cursor and Antigravity fallback packs have been removed.
- **Repo-Level Agent Context** - Added/expanded `AGENTS.md` and `MEMORY.md` as repo-specific operating rules for AI agents.

### ✅ Test Coverage
- **Widget Test Backlog** - Added a widget test plan and task backlog (`task/TASKS.md`).
- **Shared Test Harness** - Added a shared widget test harness plus batch 1-3 widget coverage tests.

### 📚 Documentation Updates
- **README Rewrite** - Rewrote the repo overview and MCP remote setup instructions, then translated the full README to English.
- **MCP Compatibility Policy** - Added `mcp-server/COMPATIBILITY_POLICY.md` documenting best-effort/unverified support for remote MCP in Claude Code and Codex host apps.
- **Beginner Skill Spec** - Added `mcp-server/FLUTTER_WIDGET_BEGINNER_SKILL_SPEC.md`.
- **Support Contact & Token Handling** - Updated support contact email and switched the Figma API key reference to an env var instead of a literal token.

---

## 🔧 Technical Improvements

### CI/CD & Quality
- Fixed pre-existing `flutter analyze` issues that were blocking the `dev` branch CI.
- Fixed MCP CI and Flutter CI failures introduced by the Phase 1-7 hardening commit.
- Fixed `activeColor` deprecation warning in `Switch`.
- Fixed `RenderFlex` overflow in UI tests by providing larger screen constraints.

### Security
- Figma API key is now read from an environment variable instead of being referenced as a literal token in docs/config.

---

## 🚀 What's Next

- Bump `pubspec.yaml` version once this batch of changes is tagged for release
- Navigation System - `go_router` integration
- API Layer - Repository pattern implementation
- Performance Optimization - Image caching and lazy loading

---

# 🚀 Release Notes v25.0.5 - New Widgets & Enhanced Preview System

**Release Date:** December 2025
**Branch:** `dev`

---

## ✨ What's New

### 🧩 New Widgets (6 Added)
- **Avatar** - Profile card with status badge (danger/warning) and skeleton loading support.
- **ImageCarousel** - Image slider with auto-play capability and custom indicators.
- **ItemList (Transaction Type)** - Enhanced list item with subtitle, amount display, and dynamic styling for transactions.
- **PreLoading** - Full-screen loading overlay with 10px blur effect and Lottie animation.
- **LottieSkeleton** - Advanced skeleton loading wrapper using Lottie animations.
- **SnackBarWidget** - Custom styled notifications with 3 types: Success, Warning, Error.

### 📚 Documentation Updates
- **WIDGETS_GUIDE.md** - Added comprehensive documentation for all 6 new widgets.
- **CODEBASE_CONTEXT.md** - Updated component count to 20 and added new categories (Display, Loading).
- **CONTRIBUTING.md** - Added "Development Tools" section covering Widgetbook and Code Generation.
- **SETUP_GUIDE.md** - Added optional Widgetbook setup instructions.

### 🛠️ Developer Experience
- **Widgetbook Integration** - Added use cases for all new widgets, enabling interactive testing.
- **Enhanced Previews** - `PreLoading` preview now simulates a transaction list background with alternating colors.
- **Transaction Simulation** - `ItemList` preview now showcases realistic transaction data with positive/negative amounts.

---

## 🔧 Technical Improvements

### Component Architecture
- **Total Components:** 20 widgets (up from 14)
- **Modular Structure:** New dedicated folders for `avatar/`, `image_carousel/`, `loading/`, `skeleton/`, `snack_bar/`.
- **Refined ItemList:** Added `ItemListType` enum for better type safety and extensibility.

### Preview System
- **Realistic Data:** Previews now use dynamic data to simulate real-world scenarios.
- **Interactive Controls:** Widgetbook knobs allow testing different states (e.g., loading, error) easily.

### 🌍 Localization Workflow
- **Centralized Management** - New `localization.json` source of truth for all translations.
- **Automated Generation** - New `tool/generate_arb.dart` script to auto-generate ARB files.
- **Documentation** - Added `lib/l10n/localization_i10n.md` guide.

---

## 🚀 What's Next

### Planned for v25.1.0
- **Navigation System** - Implement go_router integration
- **API Layer** - Repository pattern implementation
- **Testing Suite** - Unit and widget test coverage
- **Performance Optimization** - Image caching and lazy loading

---

# 🚀 Release Notes v2.1.0 - Glass Morphism & Enhanced Architecture

**Release Date:** November 2025  
**Commit:** `b557b84`  
**Branch:** `dev`

---

## ✨ What's New

### 🎨 NavigatorBar Glass Morphism Effect
- **10px Backdrop Blur** - Modern glass-morphism effect using `ImageFilter.blur`
- **Enhanced Visual Depth** - Subtle transparency with backdrop filtering
- **Improved Border Styling** - Updated border color to `alt/base/300` for better contrast
- **Fixed Scan Button Clipping** - Restructured layout with `Stack + ClipRRect` to prevent button truncation

### 🏗️ Component Architecture Improvements
- **Organized Folder Structure** - Moved components into dedicated folders:
  - `button/` - Button components with preview and documentation
  - `shortcut_menu/` - Menu components with SVG icon manipulation
- **Enhanced Documentation** - Added comprehensive guides with compliance scoring:
  - Button Components: **85/100** compliance score
  - Shortcut Menu: **70/100** compliance score

### 🎯 Design System Enhancements
- **New Design Token Variant** - Added `alt/` variant for alternative color schemes
- **Expanded Color Palette** - 100+ design tokens with improved categorization
- **Theme Consistency** - Better color token organization across all components

---

## 🔧 Technical Improvements

### Code Organization
- **14 Total Components** (up from 13)
- **18+ Documentation Files** with detailed implementation guides
- **Improved Import Paths** - Fixed import references across drawer widgets
- **Better Component Isolation** - Self-contained widgets with preview capabilities

### Performance & Quality
- **Type-Safe Design Tokens** - Consistent color access pattern
- **Responsive Design** - MediaQuery-based responsive behavior
- **Theme-Aware Components** - Full light/dark mode support
- **Multi-Language Ready** - 5 language support with proper font handling

---

## 📱 Component Updates

### NavigatorBar
- ✅ Glass-morphism blur effect (10px)
- ✅ Fixed floating scan button clipping
- ✅ Updated border color scheme
- ✅ Improved layout hierarchy

### Button Components
- ✅ Moved to dedicated `button/` folder
- ✅ Added comprehensive documentation
- ✅ 3 button types: primary, secondary, amount
- ✅ Press animations and theme support

### Shortcut Menu
- ✅ New component with SVG icon manipulation
- ✅ Dynamic color customization
- ✅ Theme-aware styling
- ✅ Comprehensive documentation

---

## 🎯 Developer Experience

### Enhanced Documentation
- **Component Compliance Scoring** - Quality metrics for each widget
- **Step-by-Step Guides** - Detailed implementation instructions
- **Preview System** - Individual testing widgets for each component
- **External Device Testing** - Web server support for real device testing

### Project Statistics
- **Total Components:** 14 widgets
- **Supported Languages:** 5 languages
- **Design Tokens:** 100+ color tokens
- **Platform Support:** 6 platforms (iOS, Android, Web, macOS, Linux, Windows)
- **Documentation Coverage:** 18+ guide files

---

## 🔄 Migration Guide

### NavigatorBar Updates
If you're using NavigatorBar, no breaking changes - the blur effect is automatically applied. The component maintains the same API while providing enhanced visual appeal.

### Button Components
Update import paths from:
```dart
import 'package:your_app/widgets/buttons.dart';
```
To:
```dart
import 'package:your_app/widgets/button/buttons.dart';
```

### New Design Tokens
You can now use the new `alt/` variant:
```dart
ThemeColors.get('light', 'alt/base/300')
```

---

## 🐛 Bug Fixes

- ✅ **NavigatorBar Scan Button Clipping** - Fixed layout hierarchy to prevent button truncation
- ✅ **Import Path Issues** - Resolved import references across drawer widgets
- ✅ **Border Color Consistency** - Updated NavigatorBar border to match design system

---

## 🚀 What's Next

### Planned for v2.2.0
- **Navigation System** - Implement go_router integration
- **API Layer** - Repository pattern implementation
- **Testing Suite** - Unit and widget test coverage
- **Performance Optimization** - Image caching and lazy loading
- **Accessibility Enhancements** - Improved a11y support

---

## 📊 Impact Summary

- **Visual Enhancement:** Modern glass-morphism effect
- **Code Quality:** Better organization and documentation
- **Developer Experience:** Improved guides and compliance scoring
- **Maintainability:** Cleaner folder structure and import paths
- **Design System:** Expanded token system with alt/ variant

---

**🎉 Ready to use in production with enhanced visual appeal and better code organization!**

**Made with ❤️ for the Flutter community**
