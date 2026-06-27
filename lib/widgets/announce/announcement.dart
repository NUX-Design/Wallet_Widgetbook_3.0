import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/assets/hugeicons/huge_icons.dart';
import 'package:mcp_test_app/config/themes/theme_constants.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart' as theme;
import 'package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart';

class AnnouncementStack extends StatefulWidget {
  const AnnouncementStack({
    super.key,
    this.messages = const [],
    this.onClose,
    this.debugMode = false,
    this.isLoading = false,
  });

  final List<String> messages;
  final VoidCallback? onClose;
  final bool debugMode;
  final bool isLoading;

  @override
  State<AnnouncementStack> createState() => _AnnouncementStackState();
}

class _AnnouncementStackState extends State<AnnouncementStack>
    with TickerProviderStateMixin {
  late List<String> _messages;

  late AnimationController _dismissController;
  late Animation<Offset> _dismissSlideAnimation;
  late Animation<double> _dismissFadeAnimation;
  late Animation<double> _dismissScaleAnimation;

  late AnimationController _promoteController;
  late Animation<Offset> _promoteSlideAnimation;
  late Animation<double> _promoteScaleAnimation;
  late Animation<double> _middleFadeAnimation;
  late Animation<double> _backScaleAnimation;
  late Animation<double> _backFadeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // Initialize messages
    _messages = List.from(widget.messages);

    // Initialize animations
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final dismissCurve = CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeInOutCubic,
    );
    _dismissSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0),
    ).animate(dismissCurve);
    _dismissFadeAnimation = Tween<double>(begin: 1, end: 0.25).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOutQuad),
    );
    _dismissScaleAnimation = Tween<double>(
      begin: 1,
      end: 1,
    ).animate(dismissCurve);

    _promoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final promoteCurve = CurvedAnimation(
      parent: _promoteController,
      curve: Curves.easeOutCubic,
    );
    _promoteSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(promoteCurve);
    _promoteScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(promoteCurve);
    _middleFadeAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _promoteController,
        curve: const Interval(0.2, 1, curve: Curves.easeOut),
      ),
    );
    _backScaleAnimation = Tween<double>(
      begin: 0.9,
      end: 0.94,
    ).animate(promoteCurve);
    _backFadeAnimation = Tween<double>(
      begin: 0.6,
      end: 0.75,
    ).animate(promoteCurve);
  }

  @override
  void didUpdateWidget(AnnouncementStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages != oldWidget.messages) {
      setState(() {
        _messages = List.from(widget.messages);
      });
    }
  }

  @override
  void dispose() {
    _dismissController.dispose();
    _promoteController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (_isAnimating || _messages.length <= 1) return;
    _isAnimating = true;

    await Future.wait([
      _dismissController.forward(),
      _promoteController.forward(),
    ]);

    _dismissController.reset();
    _promoteController.reset();

    if (!mounted) {
      _isAnimating = false;
      return;
    }

    setState(() {
      final removed = _messages.removeAt(0);
      _messages.add(removed);
    });

    _isAnimating = false;
    widget.onClose?.call();
  }

  void updateMessages(List<String> newMessages) {
    if (mounted) {
      setState(() {
        _messages = List.from(newMessages);
      });
    }
  }

  Widget _buildCard(String text, {bool isFront = false, Color? color}) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    final localeCode = Localizations.localeOf(context).languageCode;
    final announcementTextStyle =
        localeCode == 'th'
            ? GoogleFonts.notoSansThai(
              color:
                  brightnessKey == 'light'
                      ? theme.ThemeColors.get('light', 'text/base/600')
                      : theme.ThemeColors.get('dark', 'text/base/600'),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.45,
            )
            : localeCode == 'my'
            ? GoogleFonts.notoSansMyanmar(
              color:
                  brightnessKey == 'light'
                      ? theme.ThemeColors.get('light', 'text/base/600')
                      : theme.ThemeColors.get('dark', 'text/base/600'),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.45,
            )
            : GoogleFonts.notoSans(
              color:
                  brightnessKey == 'light'
                      ? theme.ThemeColors.get('light', 'text/base/600')
                      : theme.ThemeColors.get('dark', 'text/base/600'),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.45,
            );

    return Container(
      constraints: const BoxConstraints(minHeight: 65),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: color ?? theme.ThemeColors.get(brightnessKey, 'fill/base/100'),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LottieSkeleton(
            isLoading: widget.isLoading,
            child: createHugeIcon(
              megaphoneIcon,
              brightnessKey == 'light'
                  ? theme.ThemeColors.get('light', 'text/base/600')
                  : theme.ThemeColors.get('dark', 'text/base/600'),
              width: 16,
              height: 16,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: LottieSkeleton(
              isLoading: widget.isLoading,
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: announcementTextStyle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (isFront)
            GestureDetector(
              onTap: _handleClose,
              child: createHugeIcon(
                cancelIcon,
                brightnessKey == 'light'
                    ? theme.ThemeColors.get('light', 'text/base/danger')
                    : theme.ThemeColors.get('dark', 'text/base/danger'),
                width: 16,
                height: 16,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    final displayMessages =
        _messages.isEmpty
            ? List<String>.filled(3, '')
            : List<String>.from(_messages);
    while (displayMessages.length < 3) {
      displayMessages.add(displayMessages.last);
    }

    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            key: const ValueKey('card_3'),
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _backFadeAnimation,
              child: ScaleTransition(
                scale: _backScaleAnimation,
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 65),
                  decoration: BoxDecoration(
                    color: theme.ThemeColors.get(
                      brightnessKey,
                      'fill/base/500',
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            key: const ValueKey('card_2'),
            top: AppSpacing.xs,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _promoteSlideAnimation,
              child: FadeTransition(
                opacity: _middleFadeAnimation,
                child: ScaleTransition(
                  scale: _promoteScaleAnimation,
                  alignment: Alignment.topCenter,
                  child: _buildCard(
                    displayMessages[1],
                    color: theme.ThemeColors.get(
                      brightnessKey,
                      'fill/base/400',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            key: const ValueKey('card_1'),
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _dismissFadeAnimation,
              child: ScaleTransition(
                scale: _dismissScaleAnimation,
                alignment: Alignment.topCenter,
                child: SlideTransition(
                  position: _dismissSlideAnimation,
                  child: _buildCard(
                    displayMessages[0],
                    isFront: true,
                    color: theme.ThemeColors.get(
                      brightnessKey,
                      'fill/base/300',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
