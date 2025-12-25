import 'package:flutter/material.dart';
import 'package:front/controller/events/booking_controller.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/model/events/booking_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/time_utils.dart';

class ManageBookingScreen extends StatefulWidget {
  final EventModel event;

  const ManageBookingScreen({super.key, required this.event});

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  List<BookingModel> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      isLoading = true;
    });

    final fetchedBookings = await BookingController.fetchEventBookings(
      widget.event.id!,
    );

    setState(() {
      bookings = fetchedBookings;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Bookings - ${widget.event.eventName}',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context),
            color: AppColors.foregroundColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
      ),
      body: isLoading
          ? Center(child: CustomWidgets.circularProgressIndicator())
          : bookings.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: ListView.builder(
                padding: EdgeInsets.all(
                  AppSizes.getScreenWidth(context) * 0.04,
                ),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _buildBookingCard(booking);
                },
              ),
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
              'No bookings yet',
              style: TextStyle(
                color: AppColors.foregroundColor,
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.smallSpacing(context)),
            Text(
              'Bookings for this event will appear here.',
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

  Widget _buildBookingCard(BookingModel booking) {
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
      child: InkWell(
        onTap: () {
          _showBookingDetailsDialog(booking);
        },
        borderRadius: BorderRadius.circular(
          AppSizes.getScreenWidth(context) * 0.03,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.getScreenWidth(context) * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking type and delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.getScreenWidth(context) * 0.03,
                      vertical: AppSizes.getScreenHeight(context) * 0.008,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSizes.getScreenWidth(context) * 0.04,
                      ),
                      color: booking.bookingType == 'seat'
                          ? AppColors.seatEmptyColor
                          : AppColors.primary,
                    ),
                    child: Text(
                      booking.bookingType == 'seat'
                          ? 'Seat ${booking.ticketOrSeatNumber}'
                          : 'Ticket ${booking.ticketOrSeatNumber}',
                      style: TextStyle(
                        fontSize: AppSizes.bodyFontSize(context),
                        color: AppColors.foregroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.errorColor),
                    onPressed: () {
                      _showDeleteBookingDialog(booking);
                    },
                  ),
                ],
              ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.01),

              // User details
              _buildDetailRow(Icons.person, booking.userName ?? 'N/A'),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
              _buildDetailRow(Icons.email, booking.userEmail ?? 'N/A'),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
              _buildDetailRow(Icons.phone, booking.userPhoneNumber ?? 'N/A'),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.01),

              // Booking date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: AppSizes.getScreenWidth(context) * 0.04,
                    color: AppColors.shadeColor,
                  ),
                  SizedBox(width: AppSizes.getScreenWidth(context) * 0.02),
                  Text(
                    'Booked: ${_formatDate(booking.bookingDate)}',
                    style: TextStyle(
                      fontSize: AppSizes.bodyFontSize(context) * 0.9,
                      color: AppColors.shadeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return TimeUtils.formatDateTimePKT(date);
  }

  void _showBookingDetailsDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Booking Details',
            style: TextStyle(color: AppColors.foregroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  'Booking Type',
                  booking.bookingType == 'seat'
                      ? 'Seat Booking'
                      : 'Ticket Booking',
                ),
                _buildDetailItem(
                  booking.bookingType == 'seat'
                      ? 'Seat Number'
                      : 'Ticket Number',
                  booking.ticketOrSeatNumber.toString(),
                ),
                Divider(color: AppColors.shadeColor),
                _buildDetailItem('Name', booking.userName ?? 'N/A'),
                _buildDetailItem('Email', booking.userEmail ?? 'N/A'),
                _buildDetailItem('Phone', booking.userPhoneNumber ?? 'N/A'),
                Divider(color: AppColors.shadeColor),
                _buildDetailItem('Event', widget.event.eventName),
                _buildDetailItem(
                  'Event Date',
                  _formatDate(widget.event.eventDateTime),
                ),
                _buildDetailItem('Location', widget.event.eventLocation),
                _buildDetailItem(
                  'Ticket Price',
                  '\$${widget.event.ticketPrice.toStringAsFixed(2)}',
                ),
                Divider(color: AppColors.shadeColor),
                _buildDetailItem(
                  'Booking Date',
                  _formatDate(booking.bookingDate),
                ),
              ],
            ),
          ),
          backgroundColor: AppColors.backgroundColor,
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.bodyFontSize(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.foregroundColor,
                fontSize: AppSizes.bodyFontSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteBookingDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Booking',
            style: TextStyle(color: AppColors.foregroundColor),
          ),
          content: Text(
            'Are you sure you want to delete this booking for ${booking.userName}? This action cannot be undone.',
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
                final response = await BookingController.deleteBooking(
                  widget.event.id!,
                  booking.bookingType,
                  booking.ticketOrSeatNumber,
                );

                if (response) {
                  CustomSnackbars.showSuccessSnackbar(
                    context,
                    'Booking deleted successfully',
                    1,
                  );
                  Navigator.of(context).pop();
                  _fetchBookings();
                } else {
                  CustomSnackbars.showErrorSnackbar(
                    context,
                    'Failed to delete booking',
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
