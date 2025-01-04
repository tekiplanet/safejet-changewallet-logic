import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import 'package:provider/provider.dart';
import '../config/theme/theme_provider.dart';

class P2PAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onThemeToggle;
  final String? title;
  final Widget? trailing;
  final bool hasNotification;

  const P2PAppBar({
    super.key,
    this.onNotificationTap,
    this.onThemeToggle,
    this.title,
    this.trailing,
    this.hasNotification = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: isDark ? Colors.white : SafeJetColors.lightText,
                onPressed: () => Navigator.pop(context),
              ),
              
              // Title with flex
              Expanded(
                child: Text(
                  title ?? 'SafeJet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.white : SafeJetColors.lightText,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Action buttons with minimum size
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null) trailing!,
                  if (trailing != null) const SizedBox(width: 8),
                  IconButton(
                    onPressed: onNotificationTap,
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined),
                        if (hasNotification)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: SafeJetColors.secondaryHighlight,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onThemeToggle,
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
    bool hasNotification = false,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon),
          color: isDark ? Colors.white : SafeJetColors.lightText,
          iconSize: 24,
          onPressed: onTap,
        ),
        if (hasNotification)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: SafeJetColors.secondaryHighlight,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
} 