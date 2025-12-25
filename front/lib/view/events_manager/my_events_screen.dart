import 'package:flutter/material.dart';
import 'package:front/controller/events/event_controller.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/model/events/seats_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/events_manager/edit_event_screen.dart';
import 'package:front/view/events_manager/manage_booking_screen.dart';
import 'package:front/view/community_member/events/host_live_stream_screen.dart';
import 'package:front/utils/time_utils.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  List<EventModel> myEvents = [];
  late Future<List<EventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = fetchMyEvents();
  }

  Future<List<EventModel>> fetchMyEvents() {
    return EventController.fetchEvents().then((events) {
      if (mounted) {
        setState(() {
          myEvents = events;
        });
      }
      return events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundColor,
      child: FutureBuilder<List<EventModel>>(
        future: _eventsFuture,
        initialData: myEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: EdgeInsets.all(AppSizes.getScreenWidth(context) * 0.04),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return GestureDetector(
                  onLongPress: () {
                    _showDeleteDialog(event, context);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageBookingScreen(event: event),
                      ),
                    );
                  },
                  child: _buildEventCard(event, context),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.mediumPadding(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: AppSizes.extraLargeIconSize(context),
              color: AppColors.shadeColor,
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            Text(
              'No events yet',
              style: TextStyle(
                color: AppColors.foregroundColor,
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.smallSpacing(context)),
            Text(
              'Create your first automotive experience to engage the community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.bodyFontSize(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event, BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.getScreenHeight(context) * 0.02),
      color: AppColors.backgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppSizes.getScreenWidth(context) * 0.03,
        ),
        side: BorderSide(color: AppColors.shadeColor, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.getScreenWidth(context) * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event name and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.eventName,
                    style: TextStyle(
                      fontSize: AppSizes.subtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: AppColors.foregroundColor,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.foregroundColor),
                  onSelected: (value) {
                    _handleEventAction(value, event, context);
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.foregroundColor),
                          SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(color: AppColors.foregroundColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'livestream',
                      child: Row(
                        children: [
                          Icon(Icons.videocam, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Start Live Stream',
                            style: TextStyle(color: AppColors.foregroundColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.01),

            // Event description
            Text(
              event.eventDescription,
              style: TextStyle(
                fontSize: AppSizes.bodyFontSize(context),
                color: AppColors.shadeColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.015),

            // Event details
            _buildEventDetail(
              Icons.calendar_today,
              TimeUtils.formatDatePKT(event.eventDateTime),
              context,
            ),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
            _buildEventDetail(
              Icons.access_time,
              TimeUtils.formatTimePKT(event.eventDateTime),
              context,
            ),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
            _buildEventDetail(Icons.location_on, event.eventLocation, context),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.015),

            // Booking statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBookingStats(event, context),
                _buildBookingTypeChip(event.bookingType, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSizes.getScreenWidth(context) * 0.04,
          color: AppColors.shadeColor,
        ),
        SizedBox(width: AppSizes.getScreenWidth(context) * 0.02),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              color: AppColors.foregroundColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingStats(EventModel event, BuildContext context) {
    if (event.bookingType == 'seat') {
      final totalSeats =
          event.layout?.seatList.length ??
          (event.id == '1'
              ? 150
              : event.id == '3'
              ? 200
              : 100);
      final bookedSeats =
          event.layout?.seatList
              .where((seat) => seat.state == SeatState.booked)
              .length ??
          (event.id == '1'
              ? 75
              : event.id == '3'
              ? 45
              : 30);
      final percentage = totalSeats > 0
          ? (bookedSeats / totalSeats * 100).round()
          : 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$bookedSeats / $totalSeats seats booked',
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              color: AppColors.foregroundColor,
            ),
          ),
          SizedBox(height: 4),
          Container(
            width: AppSizes.getScreenWidth(context) * 0.3,
            height: AppSizes.getScreenHeight(context) * 0.008,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: AppColors.shadeColor,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: totalSeats > 0 ? bookedSeats / totalSeats : 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppSizes.getScreenWidth(context) * 0.008,
                  ),
                  color: percentage > 80
                      ? AppColors.errorColor
                      : percentage > 50
                      ? AppColors.seatReservedColor
                      : AppColors.successColor,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final totalTickets = event.ticketList!.length;
      final bookedTickets = event.ticketList!
          .where((ticket) => ticket.isBooked == true)
          .length;
      final percentage = totalTickets > 0
          ? (bookedTickets / totalTickets * 100).round()
          : 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$bookedTickets / $totalTickets tickets sold',
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              color: AppColors.foregroundColor,
            ),
          ),
          SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
          Container(
            width: AppSizes.getScreenWidth(context) * 0.3,
            height: AppSizes.getScreenHeight(context) * 0.008,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppSizes.getScreenWidth(context) * 0.008,
              ),
              color: AppColors.shadeColor,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: totalTickets > 0 ? bookedTickets / totalTickets : 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppSizes.getScreenWidth(context) * 0.008,
                  ),
                  color: percentage > 80
                      ? AppColors.errorColor
                      : percentage > 50
                      ? AppColors.seatReservedColor
                      : AppColors.successColor,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBookingTypeChip(String bookingType, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.getScreenWidth(context) * 0.03,
        vertical: AppSizes.getScreenHeight(context) * 0.008,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppSizes.getScreenWidth(context) * 0.04,
        ),
        color: bookingType == 'seat'
            ? AppColors.seatEmptyColor
            : AppColors.primary,
      ),
      child: Text(
        bookingType == 'seat' ? 'Seat Booking' : 'Ticket Booking',
        style: TextStyle(
          fontSize: AppSizes.bodyFontSize(context) * 0.9,
          color: AppColors.foregroundColor,
        ),
      ),
    );
  }

  void _handleEventAction(
    String action,
    EventModel event,
    BuildContext context,
  ) {
    switch (action) {
      case 'edit':
        _navigateToEditEvent(event, context);
        break;
      case 'livestream':
        _navigateToLiveStream(event, context);
        break;
    }
  }

  void _navigateToEditEvent(EventModel event, BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
    );
    setState(() {
      _eventsFuture = fetchMyEvents();
    });
  }

  void _navigateToLiveStream(EventModel event, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HostLiveStreamScreen(event: event),
      ),
    );
  }

  void _showDeleteDialog(EventModel event, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Event',
            style: TextStyle(color: AppColors.foregroundColor),
          ),
          content: Text(
            'Are you sure you want to delete "${event.eventName}"? This action cannot be undone.',
            style: TextStyle(color: AppColors.foregroundColor),
          ),
          backgroundColor: AppColors.backgroundColor,
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.foregroundColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: AppColors.errorColor),
              ),
              onPressed: () async {
                if (event.images.isNotEmpty) {
                  for (String imageUrl in event.images) {
                    await CloudinaryService.deleteFileByUrl(url: imageUrl);
                  }
                }
                final response = await EventController.deleteEvent(event.id!);
                if (response) {
                  setState(() {
                    _eventsFuture = fetchMyEvents();
                  });
                  CustomSnackbars.showSuccessSnackbar(
                    context,
                    '${event.eventName} deleted successfully',
                    1,
                  );
                } else {
                  CustomSnackbars.showErrorSnackbar(
                    context,
                    'Failed to delete ${event.eventName}',
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
