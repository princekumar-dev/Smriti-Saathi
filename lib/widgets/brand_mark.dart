import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  final double logoSize;
  final bool showSubtitle;
  final String? subtitle;
  final double? titleFontSize;
  final bool showDivider;
  final String title;
  final bool useOfficialBanner;
  final double bannerHeight;

  const BrandMark({
    super.key,
    this.logoSize = 52,
    this.showSubtitle = false,
    this.subtitle,
    this.titleFontSize,
    this.showDivider = false,
    this.title = 'Smriti Saathi',
    this.useOfficialBanner = false,
    this.bannerHeight = 46,
  });

  @override
  Widget build(BuildContext context) {
    if (useOfficialBanner) {
      return Image.asset(
        'assets/images/brand_lockup_trans.png',
        height: bannerHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final effectiveTitleSize = titleFontSize ?? (showSubtitle ? 24.0 : 22.0);
    final effectiveSubtitle = subtitle ?? 'Your AI Saathi for Everyday Life & Memories';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: EdgeInsets.all(logoSize * 0.1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(logoSize * 0.28),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: AppTheme.forest.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.favorite_rounded,
              color: AppTheme.forest,
              size: logoSize * 0.55,
            ),
          ),
        ),
        if (showDivider) ...[
          const SizedBox(width: 12),
          Container(
            height: logoSize * 0.76,
            width: 2.0,
            decoration: BoxDecoration(
              color: AppTheme.forest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
        ] else
          const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: effectiveTitleSize,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.deepForest,
                  letterSpacing: -0.3,
                  height: 1.12,
                ),
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 3),
                Text(
                  effectiveSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forest,
                    letterSpacing: 0.1,
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
