import 'package:flutter/material.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/model/events/booking_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/snackbars.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class TicketBookingScreen extends StatefulWidget {
  final EventModel event;

  const TicketBookingScreen({super.key, required this.event});

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  int _selectedTickets = 1;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
    _priceController.text = '\$${_totalPrice.toStringAsFixed(2)}';
  }

  void _calculateTotalPrice() {
    _totalPrice = widget.event.ticketPrice * _selectedTickets;
    _priceController.text = '\$${_totalPrice.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Tickets',
          style: TextStyle(
            fontSize: AppSizes.largeFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.appBarColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Information Card
              _buildEventInfoCard(),

              SizedBox(height: AppSizes.mediumSpacing(context)),

              // Booking Form
              _buildBookingForm(),

              SizedBox(height: AppSizes.largeSpacing(context)),

              // Book Now Button
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Card(
      elevation: AppSizes.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (widget.event.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppSizes.inputBorderRadius(context),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.event.images.first,
                  height: AppSizes.imageHeight(context),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: AppSizes.imageHeight(context),
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: AppSizes.imageHeight(context),
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.event,
                      size: AppSizes.extraLargeIconSize(context),
                      color: AppColors.shadeColor,
                    ),
                  ),
                ),
              ),

            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Event Name
            Text(
              widget.event.eventName,
              style: TextStyle(
                fontSize: AppSizes.headerFontSize(context),
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor,
              ),
            ),

            SizedBox(height: AppSizes.smallSpacing(context)),

            // Event Date & Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                  size: AppSizes.mediumIconSize(context),
                ),
                SizedBox(width: AppSizes.smallPadding(context)),
                Text(
                  DateFormat(
                    'MMM dd, yyyy - hh:mm a',
                  ).format(widget.event.eventDateTime),
                  style: TextStyle(
                    fontSize: AppSizes.bodyFontSize(context),
                    color: AppColors.shadeColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSizes.smallSpacing(context)),

            // Event Location
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: AppSizes.mediumIconSize(context),
                ),
                SizedBox(width: AppSizes.smallPadding(context)),
                Expanded(
                  child: Text(
                    widget.event.eventLocation,
                    style: TextStyle(
                      fontSize: AppSizes.bodyFontSize(context),
                      color: AppColors.shadeColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSizes.smallSpacing(context)),

            // Ticket Price
            Row(
              children: [
                Icon(
                  Icons.local_activity,
                  color: AppColors.primary,
                  size: AppSizes.mediumIconSize(context),
                ),
                SizedBox(width: AppSizes.smallPadding(context)),
                Text(
                  'Price per ticket: RS ${widget.event.ticketPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppSizes.bodyFontSize(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm() {
    return Card(
      elevation: AppSizes.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Information',
              style: TextStyle(
                fontSize: AppSizes.titleFontSize(context),
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor,
              ),
            ),

            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Number of Tickets Selector
            _buildTicketSelector(),

            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Custom Name Field
            CustomWidgets.customTextFormField(
              controller: _nameController,
              label: 'Full Name *',
              borderColor: AppColors.foregroundColor,
              textColor: AppColors.titleColor,
              fontsize: AppSizes.inputFontSize(context),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters long';
                }
                return null;
              },
            ),

            // Custom Email Field
            CustomWidgets.customTextFormField(
              controller: _emailController,
              label: 'Email Address *',
              borderColor: AppColors.foregroundColor,
              textColor: AppColors.titleColor,
              fontsize: AppSizes.inputFontSize(context),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            // Custom Phone Number Field
            CustomWidgets.customTextFormField(
              controller: _phoneController,
              label: 'Phone Number *',
              borderColor: AppColors.foregroundColor,
              textColor: AppColors.titleColor,
              fontsize: AppSizes.inputFontSize(context),
              isnumber: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.trim().length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),

            SizedBox(height: AppSizes.smallSpacing(context)),

            // Total Price Field (Disabled)
            CustomWidgets.customTextFormField(
              controller: _priceController,
              label: 'Total Price',
              borderColor: AppColors.foregroundColor,
              textColor: AppColors.titleColor,
              fontsize: AppSizes.inputFontSize(context),
              disabled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Tickets',
          style: TextStyle(
            fontSize: AppSizes.subtitleFontSize(context),
            fontWeight: FontWeight.w600,
            color: AppColors.titleColor,
          ),
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.smallPadding(context),
            vertical: AppSizes.smallSpacing(context),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.foregroundColor),
            borderRadius: BorderRadius.circular(
              AppSizes.inputBorderRadius(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _selectedTickets > 1
                    ? () {
                        setState(() {
                          _selectedTickets--;
                          _calculateTotalPrice();
                        });
                      }
                    : null,
                icon: Icon(
                  Icons.remove,
                  color: _selectedTickets > 1
                      ? AppColors.primary
                      : AppColors.shadeColor,
                  size: AppSizes.mediumIconSize(context),
                ),
              ),
              Text(
                '$_selectedTickets',
                style: TextStyle(
                  fontSize: AppSizes.largeFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
              IconButton(
                onPressed: _selectedTickets < 10
                    ? () {
                        setState(() {
                          _selectedTickets++;
                          _calculateTotalPrice();
                        });
                      }
                    : null,
                icon: Icon(
                  Icons.add,
                  color: _selectedTickets < 10
                      ? AppColors.primary
                      : AppColors.shadeColor,
                  size: AppSizes.mediumIconSize(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight(context),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookTickets,
        style: CustomWidgets.elevatedButtonStyle(context).copyWith(
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(
              vertical: AppSizes.smallPadding(context),
              horizontal: AppSizes.mediumPadding(context),
            ),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
                'Book $_selectedTickets Ticket${_selectedTickets > 1 ? 's' : ''} - \$${_totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppSizes.subtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _bookTickets() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create booking model
      final booking = BookingModel(
        userId: HiveUtils.getData('userId'),
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhoneNumber: _phoneController.text.trim(),
        eventId: widget.event.id,
        bookingType: widget.event.bookingType,
        bookingDate: DateTime.now(),
        ticketOrSeatNumber: _selectedTickets,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Implement booking API call
      // await BookingController.createBooking(booking);
      print('Booking created: ${booking.toJson()}');

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Tickets booked successfully! You will receive a confirmation email shortly.',
          3.0,
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate successful booking
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to book tickets. Please try again later.',
   
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
