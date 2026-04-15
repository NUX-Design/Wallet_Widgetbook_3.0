import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart' as theme;

enum AnnouncementState { warning, danger }

class AnnouncementWarning extends StatelessWidget {
  const AnnouncementWarning({
    super.key,
    required this.title,
    required this.description,
    this.descriptionSpans,
    this.state = AnnouncementState.warning,
  });

  final String title;
  final String description;
  final List<TextSpan>? descriptionSpans;
  final AnnouncementState state;

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    final String bgToken = state == AnnouncementState.danger ? 'danger/600' : 'warning/600';
    final String textToken = state == AnnouncementState.danger ? 'text/base/danger' : 'text/base/warning';
    final String iconToken = state == AnnouncementState.danger ? 'danger/500' : 'warning/500';

    final backgroundColor = theme.ThemeColors.get(brightnessKey, bgToken);
    final textColor = theme.ThemeColors.get(brightnessKey, textToken);
    final iconColor = theme.ThemeColors.get(brightnessKey, iconToken);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Icon
          SvgPicture.asset(
            'lib/assets/images/Alert Icon.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          // Warning Text Container
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: GoogleFonts.notoSansThaiTextTheme().bodySmall
                        ?.copyWith(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.27,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],
                descriptionSpans != null
                    ? RichText(
                      text: TextSpan(
                        style: GoogleFonts.notoSansThai(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                        children: descriptionSpans,
                      ),
                    )
                    : Text(
                      description,
                      style: GoogleFonts.notoSansThaiTextTheme().bodySmall
                          ?.copyWith(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
