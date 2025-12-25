import 'dart:math';

import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:front/view/dashboard/widgets/shared/section_header.dart';

class EventsContent extends StatelessWidget {
  const EventsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Events & RSVPs',
          subtitle: 'Keep track of what\'s coming up and where to be.',
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
        Wrap(
          spacing: AppSizes.mediumSpacing(context),
          runSpacing: AppSizes.mediumSpacing(context),
          children: [
            HoverCard(
              child: _eventCard(
                context,
                title: 'Cars & Coffee Downtown',
                date: 'Sun, 15 Dec • 09:00 AM',
                location: 'Karachi Expo Centre',
                countdown: 'In 3 days',
              ),
            ),
            HoverCard(
              child: _eventCard(
                context,
                title: 'EV Maintenance Workshop',
                date: 'Sat, 21 Dec • 11:30 AM',
                location: 'Live Streaming',
                countdown: 'In 9 days',
              ),
            ),
            HoverCard(
              child: _reminderCard(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _eventCard(
    BuildContext context, {
    required String title,
    required String date,
    required String location,
    required String countdown,
  }) {
    return Container(
      width: min(280, MediaQuery.of(context).size.width - 40),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                countdown,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
            ],
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            title,
            style: TextStyle(
              color: AppColors.titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.shadeColor),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  date,
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.smallFontSize(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.shadeColor),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.smallFontSize(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('RSVP'),
                ),
              ),
              SizedBox(width: AppSizes.smallSpacing(context)),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('Set Reminder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(BuildContext context) {
    return Container(
      width: min(280, MediaQuery.of(context).size.width - 40),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auto reminders',
            style: TextStyle(
              color: AppColors.titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            "We'll notify you 24h & 1h before your events start. Customize in settings.",
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.bodyFontSize(context),
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Row(
            children: [
              Icon(Icons.notifications_active, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Reminders enabled',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

