import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';

class HorizontalTabItem {
  const HorizontalTabItem({required this.label, this.showDot = false});

  final String label;
  final bool showDot;
}

class HorizontalTabs extends StatefulWidget {
  const HorizontalTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final List<HorizontalTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  State<HorizontalTabs> createState() => _HorizontalTabsState();
}

class _HorizontalTabsState extends State<HorizontalTabs> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ThemeColors.get(brightnessKey, 'fill/base/300'),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _TabButton(
                label: widget.tabs[i].label,
                showDot: widget.tabs[i].showDot,
                isSelected: widget.selectedIndex == i,
                isPressed: _pressedIndex == i,
                brightnessKey: brightnessKey,
                onTapDown: (_) => setState(() => _pressedIndex = i),
                onTapUp: (_) => setState(() => _pressedIndex = null),
                onTapCancel: () => setState(() => _pressedIndex = null),
                onTap: () => widget.onTabChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.isPressed,
    required this.brightnessKey,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final bool isSelected;
  final bool isPressed;
  final bool showDot;
  final String brightnessKey;
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? ThemeColors.get(brightnessKey, 'primary/400')
                    : ThemeColors.get(brightnessKey, 'fill/base/300'),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      height: 1.43,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? ThemeColors.get(
                                brightnessKey,
                                'fill/contrast/600',
                              )
                              : ThemeColors.get(brightnessKey, 'text/base/500'),
                    ),
                  ),
                ),
                if (showDot) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: ThemeColors.get(brightnessKey, 'danger/500'),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
