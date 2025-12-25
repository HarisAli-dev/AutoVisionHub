import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        boxShadow: [
          if (_hovered)
            BoxShadow(
              offset: const Offset(0, 12),
              blurRadius: 22,
              color: AppColors.primary.withOpacity(0.15),
            ),
        ],
      ),
      child: widget.child,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: widget.onTap,
          child: card,
        ),
      ),
    );
  }
}

