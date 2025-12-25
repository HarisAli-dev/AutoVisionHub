import 'package:flutter/material.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/view/dashboard/widgets/shared/clickable_section_card.dart';

class RoleHighlightsSection extends StatelessWidget {
  final VoidCallback onTap;

  const RoleHighlightsSection({
    super.key,
    required this.onTap,
  });

  String get _role =>
      (HiveUtils.getData('role') as String? ?? 'guest').toLowerCase();

  String get _title {
    if (_role == 'event_manager') {
      return 'Event Manager Highlights';
    } else if (_role == 'admin') {
      return 'Admin Highlights';
    } else {
      return 'Community Highlights';
    }
  }

  IconData get _icon {
    if (_role == 'event_manager') {
      return Icons.event_note;
    } else if (_role == 'admin') {
      return Icons.admin_panel_settings;
    } else {
      return Icons.people_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClickableSectionCard(
      icon: _icon,
      iconBackgroundColor: Colors.purpleAccent.withOpacity(0.2),
      title: _title,
      onTap: onTap,
    );
  }
}

