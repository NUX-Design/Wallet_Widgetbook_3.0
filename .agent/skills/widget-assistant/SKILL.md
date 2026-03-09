---
name: widget-assistant
description: Helps create and modify Flutter widgets in the `flutter_test_app` project, ensuring consistency with `WIDGETS_GUIDE.md` and project design patterns.
---

# Widget Assistant Skill

This skill assists in creating new Flutter reusable widgets or modifying existing ones in the `flutter_test_app`.

## Usage

When you ask to "create a widget" or "update a widget", this skill will:

1.  **Analyze Guidelines**: It will cross-reference your request with `WIDGETS_GUIDE.md` to identify existing patterns, naming conventions (e.g., `FullAmountInput`, `NavigatorBar`), and similar components.
2.  **Scaffold Code**: It will generate the widget code including:
    *   Imports (e.g., `package:flutter/material.dart`, `package:flutter_svg/flutter_svg.dart`).
    *   Class structure (typically `StatelessWidget` or `StatefulWidget`).
    *   Constructor properties with named parameters.
    *   `build` method with appropriate logical structure.
    *   Basic styling matching the App's theme (e.g., custom colors, fonts).
3.  **Documentation**: It can also suggest or draft an entry for `WIDGETS_GUIDE.md` for the new widget.

## Best Practices for this Project

*   **Files**: Widgets are typically located in `lib/widgets/<category>/<widget_name>.dart`.
*   **Assets**: Use SVGs for icons, located in `lib/assets/images/`.
*   **Localization**: Use `AppLocalizations.of(context)!` for user-facing text.
*   **Theme**: Respect the app's `ThemeData` where possible.
*   **Structure**: Keep widgets focused on a single responsibility.

## Example Request

> "Create a new widget called `TransactionStatusCard` that shows a success icon, a title, and a message. It should look similar to `AnnouncementWarning` but green."

## Steps for the Agent

1.  **Read Context**: Check `WIDGETS_GUIDE.md` to understand the `AnnouncementWarning` structure.
2.  **Draft Code**: Create `lib/widgets/status/transaction_status_card.dart`.
3.  **Review**: Ensure it compiles and follows the style guide.
