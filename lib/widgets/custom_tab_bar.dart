import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom TabBar widget implementing Contemporary Trust Minimalism design
/// with smooth animations and context-aware functionality for property categories
class CustomTabBar extends StatefulWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final int initialIndex;
  final ValueChanged<int>? onTap;
  final TabBarVariant variant;
  final bool isScrollable;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final EdgeInsetsGeometry? padding;
  final TabController? controller;

  const CustomTabBar({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTap,
    this.variant = TabBarVariant.standard,
    this.isScrollable = true,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.padding,
    this.controller,
  });

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

class _CustomTabBarState extends State<CustomTabBar>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isControllerInternal = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _tabController = widget.controller!;
    } else {
      _tabController = TabController(
        length: widget.tabs.length,
        initialIndex: widget.initialIndex,
        vsync: this,
      );
      _isControllerInternal = true;
    }

    _tabController.addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(CustomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (_isControllerInternal) {
        _tabController.removeListener(_handleTabChange);
        _tabController.dispose();
      }

      if (widget.controller != null) {
        _tabController = widget.controller!;
        _isControllerInternal = false;
      } else {
        _tabController = TabController(
          length: widget.tabs.length,
          initialIndex: widget.initialIndex,
          vsync: this,
        );
        _isControllerInternal = true;
      }

      _tabController.addListener(_handleTabChange);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    if (_isControllerInternal) {
      _tabController.dispose();
    }
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.onTap != null && _tabController.indexIsChanging) {
      widget.onTap!(_tabController.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case TabBarVariant.pills:
        return _buildPillTabBar(context);
      case TabBarVariant.segmented:
        return _buildSegmentedTabBar(context);
      case TabBarVariant.minimal:
        return _buildMinimalTabBar(context);
      default:
        return _buildStandardTabBar(context);
    }
  }

  Widget _buildStandardTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: widget.backgroundColor ?? colorScheme.surface,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isScrollable,
        labelColor: widget.selectedColor ?? colorScheme.primary,
        unselectedLabelColor: widget.unselectedColor ??
            colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: widget.indicatorColor ?? colorScheme.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: widget.tabs
            .map((tab) => Tab(
                  text: tab,
                  height: 48,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPillTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      color: widget.backgroundColor ?? colorScheme.surface,
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _tabController.index == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: GestureDetector(
              onTap: () => _tabController.animateTo(index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.selectedColor ?? colorScheme.primary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (widget.selectedColor ?? colorScheme.primary)
                        : colorScheme.outline.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.tabs[index],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : (widget.unselectedColor ??
                              colorScheme.onSurface.withValues(alpha: 0.7)),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSegmentedTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      color: widget.backgroundColor ?? colorScheme.surface,
      padding: widget.padding ?? const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: widget.selectedColor ?? colorScheme.onPrimary,
          unselectedLabelColor: widget.unselectedColor ??
              colorScheme.onSurface.withValues(alpha: 0.7),
          indicator: BoxDecoration(
            color: widget.indicatorColor ?? colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(2),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: widget.tabs
              .map((tab) => Tab(
                    text: tab,
                    height: 32,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMinimalTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      color: widget.backgroundColor ?? colorScheme.surface,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (widget.isScrollable) ...[
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.tabs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 24),
                itemBuilder: (context, index) =>
                    _buildMinimalTab(context, index),
              ),
            ),
          ] else ...[
            ...widget.tabs.asMap().entries.map((entry) {
              return Expanded(
                child: _buildMinimalTab(context, entry.key),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalTab(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.tabs[index],
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected
                    ? (widget.selectedColor ?? colorScheme.primary)
                    : (widget.unselectedColor ??
                        colorScheme.onSurface.withValues(alpha: 0.7)),
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: widget.indicatorColor ?? colorScheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Factory constructor for property category tabs
  static CustomTabBar propertyCategories({
    Key? key,
    int initialIndex = 0,
    ValueChanged<int>? onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const [
        'All',
        'Apartments',
        'Houses',
        'Villas',
        'Studios',
        'Commercial',
      ],
      initialIndex: initialIndex,
      onTap: onTap,
      variant: TabBarVariant.pills,
      controller: controller,
    );
  }

  /// Factory constructor for property filters
  static CustomTabBar propertyFilters({
    Key? key,
    int initialIndex = 0,
    ValueChanged<int>? onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const [
        'For Rent',
        'For Sale',
        'New Projects',
        'Verified',
      ],
      initialIndex: initialIndex,
      onTap: onTap,
      variant: TabBarVariant.segmented,
      isScrollable: false,
      controller: controller,
    );
  }

  /// Factory constructor for property amenities
  static CustomTabBar propertyAmenities({
    Key? key,
    int initialIndex = 0,
    ValueChanged<int>? onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const [
        'Overview',
        'Amenities',
        'Location',
        'Reviews',
        'Similar',
      ],
      initialIndex: initialIndex,
      onTap: onTap,
      variant: TabBarVariant.minimal,
      controller: controller,
    );
  }
}

/// Enum defining different TabBar variants for various use cases
enum TabBarVariant {
  standard, // Standard underlined tab bar
  pills, // Pill-shaped tabs with background
  segmented, // Segmented control style
  minimal, // Minimal tabs with bottom indicator
}
