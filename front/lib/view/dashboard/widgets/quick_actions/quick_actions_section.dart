import 'dart:math';

import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:front/view/dashboard/widgets/shared/section_header.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Quick actions',
          subtitle: 'Jump into the experience or switch roles quickly.',
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
        Wrap(
          spacing: AppSizes.smallSpacing(context),
          runSpacing: AppSizes.smallSpacing(context),
          children: [
            _quickAccessButton(
              context,
              icon: Icons.group,
              label: 'Login as Community Member',
              onTap: () => Navigator.pushNamed(
                context,
                '/signin',
                arguments: {'role': 'community_member'},
              ),
            ),
            _quickAccessButton(
              context,
              icon: Icons.event_available,
              label: 'Login as Event Manager',
              onTap: () => Navigator.pushNamed(
                context,
                '/signin',
                arguments: {'role': 'event_manager'},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickAccessButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return HoverCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min(260.0, MediaQuery.of(context).size.width - 48),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSizes.smallPadding(context),
            horizontal: AppSizes.mediumPadding(context),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.shadeColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

