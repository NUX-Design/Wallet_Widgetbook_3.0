import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    super.key,
    required this.pages,
    this.height = 150,
    this.imageHeight = 134,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 6),
  });

  final List<Widget> pages;
  final double height;
  final double imageHeight;
  final bool autoPlay;
  final Duration autoPlayInterval;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer; // Add timer variable

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.pages.isNotEmpty) {
      _startAutoPlay();
    }
  }

  @override
  void didUpdateWidget(covariant ImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.pages.length != widget.pages.length) {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;

      if (widget.autoPlay && widget.pages.isNotEmpty) {
        _startAutoPlay();
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (mounted && widget.autoPlay && widget.pages.isNotEmpty) {
        final nextPage = (_currentPage + 1) % widget.pages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel(); // Cancel timer
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Image Area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: widget.imageHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return widget.pages[index];
                },
              ),
            ),
          ),

          // Indicators
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pages.length, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: isSelected ? 15 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? ThemeColors.get(brightnessKey, 'primary/400')
                            : ThemeColors.get(
                              brightnessKey,
                              'stroke/contrast/600',
                            ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
