import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MemoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconBackgroundColor;

  const MemoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.onTap,
    this.iconBackgroundColor = AppTheme.sage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: AppTheme.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          side: const BorderSide(color: AppTheme.divider, width: 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, size: 32, color: AppTheme.forest),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 32),
                ],
              ),
              const SizedBox(height: 14),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: AppTheme.forest, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Tap to open and listen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forest,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),);
  }
}
