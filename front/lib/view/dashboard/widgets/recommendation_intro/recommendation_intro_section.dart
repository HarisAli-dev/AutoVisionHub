import 'package:flutter/material.dart';
import 'package:front/view/dashboard/widgets/shared/clickable_section_card.dart';

class RecommendationIntroSection extends StatelessWidget {
  final VoidCallback onTap;

  const RecommendationIntroSection({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClickableSectionCard(
      icon: Icons.recommend,
      iconBackgroundColor: Colors.amberAccent.withOpacity(0.2),
      title: 'Smart Recommendations',
      onTap: onTap,
    );
  }
}

