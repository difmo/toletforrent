import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom BottomNavigationBar widget implementing Contemporary Trust Minimalism
/// with adaptive navigation that intelligently hides during scroll for immersive browsing
class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final BottomBarVariant variant;
  final bool isVisible;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  const CustomBottomBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.variant = BottomBarVariant.standard,
    this.isVisible = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CustomBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    switch (widget.variant) {
      case BottomBarVariant.floating:
        return _buildFloatingBottomBar(context);
      case BottomBarVariant.minimal:
        return _buildMinimalBottomBar(context);
      default:
        return _buildStandardBottomBar(context);
    }
  }

  Widget _buildStandardBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: _handleTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: widget.selectedItemColor ?? colorScheme.primary,
          unselectedItemColor: widget.unselectedItemColor ??
              colorScheme.onSurface.withValues(alpha: 0.6),
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
          items: _getBottomNavigationBarItems(context),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: _handleTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor:
                  widget.selectedItemColor ?? colorScheme.primary,
              unselectedItemColor: widget.unselectedItemColor ??
                  colorScheme.onSurface.withValues(alpha: 0.6),
              selectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.4,
              ),
              items: _getBottomNavigationBarItems(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _getMinimalBottomBarItems(context),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _getBottomNavigationBarItems(
      BuildContext context) {
    return [
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(Icons.home_outlined, Icons.home, 0),
        label: 'Home',
        tooltip: 'Home - Browse featured properties',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(Icons.search_outlined, Icons.search, 1),
        label: 'Search',
        tooltip: 'Search - Find your perfect property',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(
            Icons.favorite_border_outlined, Icons.favorite, 2),
        label: 'Favorites',
        tooltip: 'Favorites - Your saved properties',
      ),
      BottomNavigationBarItem(
        icon:
            _buildAnimatedIcon(Icons.chat_bubble_outline, Icons.chat_bubble, 3),
        label: 'Messages',
        tooltip: 'Messages - Chat with property owners',
      ),
      BottomNavigationBarItem(
        icon: _buildAnimatedIcon(Icons.person_outline, Icons.person, 4),
        label: 'Profile',
        tooltip: 'Profile - Manage your account',
      ),
    ];
  }

  List<Widget> _getMinimalBottomBarItems(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.search_outlined, Icons.search, 'Search'),
      (Icons.favorite_border_outlined, Icons.favorite, 'Favorites'),
      (Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = widget.currentIndex == index;

      return GestureDetector(
        onTap: () => _handleTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.selectedItemColor ?? colorScheme.primary)
                          .withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? item.$2 : item.$1,
                  color: isSelected
                      ? (widget.selectedItemColor ?? colorScheme.primary)
                      : (widget.unselectedItemColor ??
                          colorScheme.onSurface.withValues(alpha: 0.6)),
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? (widget.selectedItemColor ?? colorScheme.primary)
                      : (widget.unselectedItemColor ??
                          colorScheme.onSurface.withValues(alpha: 0.6)),
                  letterSpacing: 0.4,
                ),
                child: Text(item.$3),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAnimatedIcon(
      IconData unselectedIcon, IconData selectedIcon, int index) {
    final isSelected = widget.currentIndex == index;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        key: ValueKey(isSelected),
        size: 24,
      ),
    );
  }

  void _handleTap(int index) {
    if (widget.onTap != null) {
      widget.onTap!(index);
    }

    // Provide haptic feedback for better user experience
    _provideFeedback();

    // Navigate to appropriate screens based on index
    _navigateToScreen(index);
  }

  void _provideFeedback() {
    // Light haptic feedback for tab selection
    // HapticFeedback.lightImpact(); // Uncomment when haptic feedback is needed
  }

  void _navigateToScreen(int index) {
    final routes = [
      '/home-screen', // 0: Home
      '/property-search-screen', // 1: Search
      '/favorites-screen', // 2: Favorites
      '/messages-screen', // 3: Messages
      '/profile-screen', // 4: Profile
    ];

    if (index < routes.length) {
      // Only navigate if it's a different screen
      if (widget.currentIndex != index) {
        Navigator.pushNamed(context, routes[index]);
      }
    }
  }
}

/// Enum defining different BottomBar variants for various use cases
enum BottomBarVariant {
  standard, // Standard bottom navigation bar
  floating, // Floating bottom navigation bar with rounded corners
  minimal, // Minimal bottom bar with custom layout
}
