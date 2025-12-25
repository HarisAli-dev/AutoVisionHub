import 'package:flutter/material.dart';
import 'package:front/model/events/seats_model.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/providers/seat_provider.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';
import 'package:provider/provider.dart';
import 'package:front/services/event_reminder_service.dart';
import 'package:intl_mobile_field/intl_mobile_field.dart';

class SeatBookingScreen extends StatefulWidget {
  final EventModel event;
  final String layoutName;
  final int gridWidth;
  final int gridHeight;
  final List<Seat> seats;

  const SeatBookingScreen({
    Key? key,
    required this.event,
    required this.layoutName,
    required this.gridWidth,
    required this.gridHeight,
    required this.seats,
  }) : super(key: key);

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  double _gridSize = 40.0;
  final TransformationController _transformationController =
      TransformationController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize the seat provider with customer role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SeatProvider>(
        context,
        listen: false,
      ).initializeSeats(widget.seats, role: UserRole.community_member);
    });
  }

  void _showBookingForm() {
    final seatProvider = Provider.of<SeatProvider>(context, listen: false);

    if (!seatProvider.hasSelectedSeats) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please select at least one seat to book',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.cardBorderRadius(context)),
        ),
      ),
      builder: (context) => _buildBookingForm(),
    );
  }

  Widget _buildBookingForm() {
    return Consumer<SeatProvider>(
      builder: (context, seatProvider, child) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.mediumPadding(context),
            right: AppSizes.mediumPadding(context),
            top: AppSizes.mediumPadding(context),
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                AppSizes.mediumPadding(context),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Book ${seatProvider.selectedSeatsCount} Seat${seatProvider.selectedSeatsCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: AppSizes.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.primary),
                    ),
                  ],
                ),

                SizedBox(height: AppSizes.smallSpacing(context)),

                // Selected seats info
                Container(
                  padding: EdgeInsets.all(AppSizes.smallPadding(context)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppSizes.inputBorderRadius(context),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Seats:',
                        style: TextStyle(
                          fontSize: AppSizes.bodyFontSize(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: AppSizes.smallSpacing(context) / 2),
                      Wrap(
                        spacing: 8,
                        children: seatProvider.selectedSeats.map((seatNumber) {
                          return Chip(
                            label: Text(
                              'Seat ${seatNumber + 1}',
                              style: TextStyle(
                                fontSize: AppSizes.smallFontSize(context),
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            deleteIcon: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            onDeleted: () {
                              seatProvider.toggleSeat(seatNumber);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSizes.mediumSpacing(context)),

                // Booking form fields
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
                    return null;
                  },
                ),

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

                IntlMobileField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    labelStyle: TextStyle(color: AppColors.titleColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.foregroundColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.foregroundColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.foregroundColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: TextStyle(
                    color: AppColors.titleColor,
                    fontSize: AppSizes.inputFontSize(context),
                  ),
                  dropdownTextStyle: TextStyle(color: AppColors.titleColor),
                  initialCountryCode: 'PK',
                  disableLengthCheck: false,
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (value) {
                    if (value == null || value.completeNumber.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSizes.mediumSpacing(context)),

                // Book button
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight(context),
                  child: ElevatedButton(
                    onPressed: seatProvider.isLoading ? null : _bookSeats,
                    style: CustomWidgets.elevatedButtonStyle(context),
                    child: seatProvider.isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            'Book ${seatProvider.selectedSeatsCount} Seat${seatProvider.selectedSeatsCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: AppSizes.subtitleFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _bookSeats() async {
    if (!_formKey.currentState!.validate()) return;

    final seatProvider = Provider.of<SeatProvider>(context, listen: false);
    final selectedSeatsNumbers = List<int>.from(seatProvider.selectedSeats);

    final success = await seatProvider.bookSelectedSeats(
      eventId: widget.event.id!,
      userName: _nameController.text.trim(),
      userEmail: _emailController.text.trim(),
      userPhone: _phoneController.text.trim(),
    );

    if (success) {
      await EventReminderService.scheduleEventReminders(
        event: widget.event,
        bookingSummary: selectedSeatsNumbers.isEmpty
            ? null
            : 'Seats ${selectedSeatsNumbers.map((e) => e + 1).join(', ')} reserved.',
      );
      Navigator.pop(context, true); // Close the form and notify parent
      CustomSnackbars.showSuccessSnackbar(
        context,
        'Seats booked successfully!',
        1.0,
      );
      _clearForm();
    } else {
      CustomSnackbars.showErrorSnackbar(
        context,
        seatProvider.errorMessage ?? 'Failed to book seats',
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SeatProvider>(
      builder: (context, seatProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Book Your Seats',
              style: TextStyle(
                fontSize: AppSizes.largeFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.appBarColor,
            actions: [
              if (seatProvider.hasSelectedSeats)
                IconButton(
                  onPressed: seatProvider.clearSelections,
                  icon: Icon(Icons.clear_all),
                  tooltip: 'Clear selections',
                ),
            ],
          ),
          body: Column(
            children: [
              // Seat statistics bar
              _buildStatisticsBar(seatProvider),

              // Legend
              _buildLegend(),

              // Seat grid
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(AppSizes.smallPadding(context)),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.foregroundColor,
                      width: 0.5,
                    ),
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(
                      AppSizes.inputBorderRadius(context),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppSizes.inputBorderRadius(context),
                    ),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.1,
                      maxScale: 3.0,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.gridWidth,
                          childAspectRatio: 1,
                        ),
                        itemCount: widget.gridWidth * widget.gridHeight,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final x = index % widget.gridWidth;
                          final y = index ~/ widget.gridWidth;
                          final seatList = seatProvider.seats.where(
                            (s) => s.gridX == x && s.gridY == y,
                          );
                          final seat = seatList.isNotEmpty
                              ? seatList.first
                              : null;

                          return GestureDetector(
                            onTap: seat != null
                                ? () {
                                    final success = seatProvider.toggleSeat(
                                      seat.seatNumber,
                                    );
                                    if (!success &&
                                        seatProvider.errorMessage != null) {
                                      CustomSnackbars.showErrorSnackbar(
                                        context,
                                        seatProvider.errorMessage!,
                                      );
                                    }
                                  }
                                : null,
                            child: Container(
                              margin: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: seat != null
                                    ? seatProvider.getSeatColor(seat)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border:
                                    seat != null &&
                                        seatProvider.selectedSeats.contains(
                                          seat.seatNumber,
                                        )
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: seat != null
                                  ? Center(
                                      child: Text(
                                        '${seat.seatNumber + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: (_gridSize * 0.3).clamp(
                                            6.0,
                                            16.0,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: seatProvider.hasSelectedSeats
              ? Container(
                  padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _showBookingForm,
                    style: CustomWidgets.elevatedButtonStyle(context).copyWith(
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(
                          vertical: AppSizes.smallPadding(context),
                        ),
                      ),
                    ),
                    child: Text(
                      'Book ${seatProvider.selectedSeatsCount} Selected Seat${seatProvider.selectedSeatsCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: AppSizes.subtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildStatisticsBar(SeatProvider seatProvider) {
    final stats = seatProvider.getSeatStatistics();

    return Container(
      padding: EdgeInsets.all(AppSizes.smallPadding(context)),
      margin: EdgeInsets.all(AppSizes.smallPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          AppSizes.inputBorderRadius(context),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Total', stats['total']!, AppColors.foregroundColor),
          _buildStatItem(
            'Available',
            stats['empty']!,
            AppColors.seatEmptyColor,
          ),
          _buildStatItem('Booked', stats['booked']!, AppColors.seatBookedColor),
          _buildStatItem(
            'Reserved',
            stats['reserved']!,
            AppColors.seatReservedColor,
          ),
          if (stats['selected']! > 0)
            _buildStatItem('Selected', stats['selected']!, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: AppSizes.subtitleFontSize(context),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.smallFontSize(context),
            color: AppColors.shadeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.mediumPadding(context),
        vertical: AppSizes.smallPadding(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Available', AppColors.seatEmptyColor),
          _buildLegendItem('Booked', AppColors.seatBookedColor),
          _buildLegendItem('Reserved', AppColors.seatReservedColor),
          _buildLegendItem('Selected', Colors.green),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.smallFontSize(context),
            color: AppColors.foregroundColor,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
