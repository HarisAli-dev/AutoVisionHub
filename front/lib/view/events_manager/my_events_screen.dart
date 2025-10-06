import 'package:flutter/material.dart';
import 'package:front/controller/events/event_controller.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/model/events/seats_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/events_manager/edit_event_screen.dart';
import 'package:front/view/community_member/events/live_stream_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  List<EventModel> myEvents = [];
  @override
  void initState() {
    super.initState();
    fetchMyEvents();
  }

  void fetchMyEvents() {
    EventController.fetchEvents().then((events) {
      setState(() {
        myEvents = events;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Events',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context),
            color: AppColors.foregroundColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
      ),
      body: FutureBuilder(
        future: EventController.fetchEvents(),
        initialData: myEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final events = snapshot.data ?? [];
            return ListView.builder(
              padding: EdgeInsets.all(AppSizes.getScreenWidth(context) * 0.04),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return GestureDetector(
                  onLongPress: () {
                    // Show delete confirmation dialog
                    _showDeleteDialog(event);
                  },
                  onTap: () {
                    //TODO: show booking details
                  },
                  child: _buildEventCard(event),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
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
                    _handleEventAction(value, event);
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
              '${event.eventDateTime.day}/${event.eventDateTime.month}/${event.eventDateTime.year}',
            ),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
            _buildEventDetail(
              Icons.access_time,
              '${event.eventDateTime.hour.toString().padLeft(2, '0')}:${event.eventDateTime.minute.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
            _buildEventDetail(Icons.location_on, event.eventLocation),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.015),

            // Booking statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBookingStats(event),
                _buildBookingTypeChip(event.bookingType),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text) {
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

  Widget _buildBookingStats(EventModel event) {
    if (event.bookingType == 'seat') {
      // Use layout data if available, otherwise mock data
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
      // Mock data for demonstration - replace with actual booking logic
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

  Widget _buildBookingTypeChip(String bookingType) {
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

  void _handleEventAction(String action, EventModel event) {
    switch (action) {
      case 'edit':
        _navigateToEditEvent(event);
        break;
      case 'livestream':
        _navigateToLiveStream(event);
        break;
    }
  }

  void _navigateToEditEvent(EventModel event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
    );
    // Refresh the list if needed
    setState(() {});
  }

  void _navigateToLiveStream(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamScreen(
          event: event,
          isHost: true, // Event manager is always the host
        ),
      ),
    );
  }

  void _showDeleteDialog(EventModel event) {
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
                  // Delete all event images
                  for (String imageUrl in event.images) {
                    await CloudinaryService.deleteFileByUrl(url: imageUrl);
                  }
                }
                final response = await EventController.deleteEvent(event.id!);
                if (response) {
                  fetchMyEvents();
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
