import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom AppBar widget implementing Contemporary Trust Minimalism design
/// with adaptive navigation and context-aware functionality for property rental app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.variant = AppBarVariant.standard,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.flexibleSpace,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      title: _buildTitle(context),
      leading: _buildLeading(context),
      actions: _buildActions(context),
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? _getBackgroundColor(theme),
      foregroundColor: foregroundColor ?? _getForegroundColor(theme),
      elevation: elevation ?? _getElevation(),
      centerTitle: centerTitle,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.shadowColor,
      titleTextStyle: _getTitleTextStyle(theme),
      iconTheme: IconThemeData(
        color: foregroundColor ?? _getForegroundColor(theme),
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: foregroundColor ?? _getForegroundColor(theme),
        size: 24,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    switch (variant) {
      case AppBarVariant.search:
        return _buildSearchTitle(context);
      case AppBarVariant.property:
        return _buildPropertyTitle(context);
      case AppBarVariant.profile:
        return _buildProfileTitle(context);
      default:
        return Text(title);
    }
  }

  Widget _buildSearchTitle(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.isEmpty ? 'Search Properties' : title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'VERIFIED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTitle(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.person_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title.isEmpty ? 'Profile' : title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (automaticallyImplyLeading && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
        splashRadius: 20,
      );
    }

    return null;
  }

  List<Widget>? _buildActions(BuildContext context) {
    final defaultActions = _getDefaultActions(context);

    if (actions != null) {
      return [...defaultActions, ...actions!];
    }

    return defaultActions.isNotEmpty ? defaultActions : null;
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    switch (variant) {
      case AppBarVariant.home:
        return [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _handleNotifications(context),
            tooltip: 'Notifications',
            splashRadius: 20,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _handleProfile(context),
            tooltip: 'Profile',
            splashRadius: 20,
          ),
        ];
      case AppBarVariant.search:
        return [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () => _handleFilters(context),
            tooltip: 'Filters',
            splashRadius: 20,
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _handleMapView(context),
            tooltip: 'Map View',
            splashRadius: 20,
          ),
        ];
      case AppBarVariant.property:
        return [
          IconButton(
            icon: const Icon(Icons.favorite_border_outlined),
            onPressed: () => _handleFavorite(context),
            tooltip: 'Add to Favorites',
            splashRadius: 20,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _handleShare(context),
            tooltip: 'Share Property',
            splashRadius: 20,
          ),
        ];
      default:
        return [];
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (variant) {
      case AppBarVariant.transparent:
        return Colors.transparent;
      case AppBarVariant.primary:
        return theme.colorScheme.primary;
      default:
        return theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    }
  }

  Color _getForegroundColor(ThemeData theme) {
    switch (variant) {
      case AppBarVariant.primary:
        return theme.colorScheme.onPrimary;
      case AppBarVariant.transparent:
        return theme.colorScheme.onSurface;
      default:
        return theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    }
  }

  double _getElevation() {
    switch (variant) {
      case AppBarVariant.transparent:
        return 0;
      case AppBarVariant.elevated:
        return 4;
      default:
        return 2;
    }
  }

  TextStyle _getTitleTextStyle(ThemeData theme) {
    return GoogleFonts.inter(
      fontSize: variant == AppBarVariant.property ? 18 : 20,
      fontWeight: FontWeight.w500,
      color: foregroundColor ?? _getForegroundColor(theme),
      letterSpacing: 0.15,
    );
  }

  // Navigation handlers
  void _handleNotifications(BuildContext context) {
    // Navigate to notifications or show notification panel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications feature coming soon')),
    );
  }

  void _handleProfile(BuildContext context) {
    Navigator.pushNamed(context, '/authentication-screen');
  }

  void _handleFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(context),
    );
  }

  void _handleMapView(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map view feature coming soon')),
    );
  }

  void _handleFavorite(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to favorites'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => Navigator.pushNamed(context, '/home-screen'),
        ),
      ),
    );
  }

  void _handleShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Property link copied to clipboard')),
    );
  }

  Widget _buildFilterBottomSheet(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Price Range',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                RangeSlider(
                  values: const RangeValues(10000, 50000),
                  min: 5000,
                  max: 100000,
                  divisions: 20,
                  labels: const RangeLabels('₹10K', '₹50K'),
                  onChanged: (values) {},
                ),
                const SizedBox(height: 24),
                Text(
                  'Property Type',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Apartment', 'House', 'Villa', 'Studio']
                      .map((type) => FilterChip(
                            label: Text(type),
                            selected: type == 'Apartment',
                            onSelected: (selected) {},
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/property-search-screen');
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

/// Enum defining different AppBar variants for various screens
enum AppBarVariant {
  standard,
  home,
  search,
  property,
  profile,
  transparent,
  primary,
  elevated,
}
