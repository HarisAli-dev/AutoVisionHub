import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class TabSwitcher extends StatelessWidget {
  final List<String> tabs;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const TabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final bool isSelected = selectedTab == index;
          return Padding(
            padding: EdgeInsets.only(
              right: AppSizes.smallSpacing(context),
            ),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: isSelected,
              onSelected: (_) {
                onTabChanged(index);
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              backgroundColor: AppColors.surfaceColor,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.shadeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ),
    );
  }
}

