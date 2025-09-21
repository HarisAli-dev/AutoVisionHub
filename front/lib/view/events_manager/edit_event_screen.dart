import 'package:flutter/material.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/controller/events/event_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditEventScreen extends StatefulWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDescriptionController =
      TextEditingController();
  final TextEditingController eventLocationController = TextEditingController();
  final TextEditingController totalTicketsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool isSeatBooking = true; // Default to seat booking
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<XFile> selectedImages = []; // List to store selected images
  List<String> existingImageUrls = []; // List to store existing image URLs
  DateTime? selectedDateTime; // Store selected date and time

  @override
  void initState() {
    super.initState();
    // Pre-populate the form with existing event data
    eventNameController.text = widget.event.eventName;
    eventDescriptionController.text = widget.event.eventDescription;
    eventLocationController.text = widget.event.eventLocation;
    isSeatBooking = widget.event.bookingType == 'seat';
    priceController.text = widget.event.ticketPrice.toString();
    // Use the DateTime directly from the model
    selectedDateTime = widget.event.eventDateTime;

    if (!isSeatBooking) {
      totalTicketsController.text =
          widget.event.ticketList?.length.toString() ?? '';
    }

    // Load existing images if any
    if (widget.event.images.isNotEmpty) {
      existingImageUrls = List<String>.from(widget.event.images);
    }
  }

  @override
  void dispose() {
    eventNameController.dispose();
    eventDescriptionController.dispose();
    eventLocationController.dispose();
    totalTicketsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Event',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context),
            color: AppColors.foregroundColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.getScreenWidth(context) * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name
              CustomWidgets.customTextFormField(
                controller: eventNameController,
                label: 'Event Name',
                borderColor: AppColors.shadeColor,
                textColor: AppColors.foregroundColor,
                fontsize: AppSizes.inputFontSize(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event name';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),

              // Event Description
              CustomWidgets.customTextFormField(
                controller: eventDescriptionController,
                label: 'Event Description',
                borderColor: AppColors.shadeColor,
                textColor: AppColors.foregroundColor,
                fontsize: AppSizes.inputFontSize(context),
                maxLine: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),

              // Date and Time Picker Field
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: _selectDateTime,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.getScreenWidth(context) * 0.04,
                      vertical: AppSizes.getScreenHeight(context) * 0.015,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.shadeColor),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                          size: AppSizes.getScreenWidth(context) * 0.05,
                        ),
                        SizedBox(
                          width: AppSizes.getScreenWidth(context) * 0.03,
                        ),
                        Expanded(
                          child: Text(
                            selectedDateTime == null
                                ? 'Select Date & Time'
                                : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} at ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: AppSizes.inputFontSize(context),
                              color: selectedDateTime == null
                                  ? AppColors.shadeColor
                                  : AppColors.foregroundColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),

              // Event Location
              CustomWidgets.customTextFormField(
                controller: eventLocationController,
                label: 'Event Location',
                borderColor: AppColors.shadeColor,
                textColor: AppColors.foregroundColor,
                fontsize: AppSizes.inputFontSize(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event location';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
              CustomWidgets.customTextFormField(
                controller: priceController,
                label: isSeatBooking
                    ? 'Seat Price (in RS)'
                    : 'Ticket Price (in RS)',
                borderColor: AppColors.shadeColor,
                textColor: AppColors.foregroundColor,
                fontsize: AppSizes.inputFontSize(context),
                isnumber: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ${isSeatBooking ? 'seat' : 'ticket'} price';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
              // Event Images Section
              Text(
                'Event Images',
                style: TextStyle(
                  fontSize: AppSizes.inputFontSize(context),
                  color: AppColors.foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.01),
              _buildImageSelector(),

              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),

              // Booking Type Display (Read-only)
              CustomWidgets.customTextFormField(
                controller: TextEditingController(
                  text: isSeatBooking ? 'Seat Booking' : 'Ticket Booking',
                ),
                label: 'Booking Type',
                borderColor: AppColors.shadeColor,
                textColor: AppColors.foregroundColor,
                fontsize: AppSizes.inputFontSize(context),
                disabled: true, // Make it read-only
              ),

              // Total Tickets field (only for ticket booking) read-only
              if (!isSeatBooking) ...[
                SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
                CustomWidgets.customTextFormField(
                  controller: totalTicketsController,
                  label: 'Total Tickets',
                  borderColor: AppColors.shadeColor,
                  textColor: AppColors.foregroundColor,
                  fontsize: AppSizes.inputFontSize(context),
                  isnumber: true,
                  disabled: true, // Make it read-only
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Total tickets not available';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.04),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (selectedDateTime == null) {
                        CustomSnackbars.showErrorSnackbar(
                          context,
                          'Please select event date and time',
              
                        );
                        return;
                      }

                      if (isSeatBooking) {
                        // Navigate to seating designer for seat booking events
                        _saveUpdatedSeatEvent();
                      } else {
                        // Save the ticket booking event
                        _saveUpdatedTicketEvent();
                      }
                    }
                  },
                  style: CustomWidgets.elevatedButtonStyle(context),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSizes.getScreenHeight(context) * 0.015,
                    ),
                    child: Text(
                      'Save Event',
                      style: TextStyle(
                        fontSize: AppSizes.inputFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to select date and time
  Future<void> _selectDateTime() async {
    // First, pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.backgroundColor,
              onSurface: AppColors.foregroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Then, pick the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedDateTime != null
            ? TimeOfDay.fromDateTime(selectedDateTime!)
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.backgroundColor,
                onSurface: AppColors.foregroundColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Build image selector widget (for both existing URLs and new images)
  Widget _buildImageSelector() {
    final totalImages = existingImageUrls.length + selectedImages.length;

    return Container(
      height: AppSizes.getScreenHeight(context) * 0.12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages + 1, // +1 for the add button
        itemBuilder: (context, index) {
          if (index == totalImages) {
            // Add image button
            return _buildAddImageButton();
          } else if (index < existingImageUrls.length) {
            // Display existing image from URL
            return _buildExistingImagePreview(existingImageUrls[index], index);
          } else {
            // Display newly selected image
            final newImageIndex = index - existingImageUrls.length;
            return _buildNewImagePreview(
              selectedImages[newImageIndex],
              newImageIndex,
            );
          }
        },
      ),
    );
  }

  // Build add image button
  Widget _buildAddImageButton() {
    return Container(
      width: AppSizes.getScreenWidth(context) * 0.25,
      margin: EdgeInsets.only(right: AppSizes.getScreenWidth(context) * 0.02),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.shadeColor, width: 2),
        borderRadius: BorderRadius.circular(
          AppSizes.getScreenWidth(context) * 0.02,
        ),
        color: AppColors.backgroundColor,
      ),
      child: InkWell(
        onTap: _showImagePickerOptions,
        borderRadius: BorderRadius.circular(
          AppSizes.getScreenWidth(context) * 0.02,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: AppSizes.getScreenWidth(context) * 0.08,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSizes.getScreenHeight(context) * 0.005),
            Text(
              'Add Image',
              style: TextStyle(
                fontSize: AppSizes.bodyFontSize(context),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build existing image preview from URL
  Widget _buildExistingImagePreview(String imageUrl, int index) {
    return Container(
      width: AppSizes.getScreenWidth(context) * 0.25,
      margin: EdgeInsets.only(right: AppSizes.getScreenWidth(context) * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppSizes.getScreenWidth(context) * 0.02,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              AppSizes.getScreenWidth(context) * 0.02,
            ),
            child: Image.network(
              imageUrl,
              width: AppSizes.getScreenWidth(context) * 0.25,
              height: AppSizes.getScreenHeight(context) * 0.12,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: AppSizes.getScreenWidth(context) * 0.25,
                  height: AppSizes.getScreenHeight(context) * 0.12,
                  color: AppColors.shadeColor,
                  child: Icon(Icons.error, color: AppColors.errorColor),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () async {
                final response =
                    await EventController.deleteImageFromCloudinary(imageUrl);
                if (response) {
                  _removeExistingImage(index);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: AppSizes.getScreenWidth(context) * 0.05,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build new image preview from file
  Widget _buildNewImagePreview(XFile image, int index) {
    return Container(
      width: AppSizes.getScreenWidth(context) * 0.25,
      margin: EdgeInsets.only(right: AppSizes.getScreenWidth(context) * 0.02),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppSizes.getScreenWidth(context) * 0.02,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              AppSizes.getScreenWidth(context) * 0.02,
            ),
            child: Image.file(
              File(image.path),
              width: AppSizes.getScreenWidth(context) * 0.25,
              height: AppSizes.getScreenHeight(context) * 0.12,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewImage(index),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: AppSizes.getScreenWidth(context) * 0.05,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.getScreenWidth(context) * 0.05),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: AppColors.foregroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImagesFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: AppColors.primary),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: AppColors.foregroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick images from gallery
  void _pickImagesFromGallery() async {
    final List<XFile> images = await EventController.pickImages();
    if (images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images);
      });
    }
  }

  // Pick image from camera
  void _pickImageFromCamera() async {
    final XFile? image = await EventController.pickImageFromCamera();
    if (image != null) {
      setState(() {
        selectedImages.add(image);
      });
    }
  }

  // Remove existing image from URL list
  void _removeExistingImage(int index) {
    setState(() {
      existingImageUrls.removeAt(index);
    });
  }

  // Remove new image from selection
  void _removeNewImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  void _saveUpdatedTicketEvent() async {
    // save new images to cloudinary and get their urls
    final response = await EventController.uploadImagesToCloudinary(
      selectedImages,
    );
    if (response.statusCode == 200) {
      final List<String> imageUrls = response.body['secure_urls'];
      await EventController.saveEditedTicketEvent(
        eventId: widget.event.id!,
        eventName: eventNameController.text,
        eventDescription: eventDescriptionController.text,
        eventDateTime: selectedDateTime!,
        eventLocation: eventLocationController.text,
        ticketPrice: double.parse(priceController.text),
        totalTickets: widget.event.ticketList!,
        images: [...existingImageUrls, ...imageUrls],
      );
      CustomSnackbars.showSuccessSnackbar(
        context,
        'Event updated successfully',
        2.0,
      );

      // Create updated event model
      final updatedEvent = EventModel(
        id: widget.event.id,
        eventName: eventNameController.text,
        eventDescription: eventDescriptionController.text,
        eventDateTime: selectedDateTime!,
        eventLocation: eventLocationController.text,
        bookingType: isSeatBooking ? 'seat' : 'ticket',
        images: [...existingImageUrls, ...selectedImages.map((e) => e.path)],
        ticketPrice: double.parse(priceController.text),
        createdBy: widget.event.createdBy,
        layout: widget.event.layout,
        ticketList: widget.event.ticketList,
        createdAt: widget.event.createdAt,
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, updatedEvent);
    }
  }

  // Save the edited seat event
  void _saveUpdatedSeatEvent() async {
    final response = await EventController.saveEditedSeatEvent(
      eventId: widget.event.id!,
      eventName: eventNameController.text,
      eventDescription: eventDescriptionController.text,
      eventDateTime: selectedDateTime!,
      eventLocation: eventLocationController.text,
      ticketPrice: double.parse(priceController.text),
      layout: widget.event.layout!,
      images: [...existingImageUrls, ...selectedImages.map((e) => e.path)],
    );
    print(
      'Save Edited Seat Event Response: ${response.statusCode} - ${response.body}',
    );
    CustomSnackbars.showSuccessSnackbar(
      context,
      'Event updated successfully',
      2.0,
    );

    // Create updated event model
    final updatedEvent = EventModel(
      id: widget.event.id,
      eventName: eventNameController.text,
      eventDescription: eventDescriptionController.text,
      eventDateTime: selectedDateTime!,
      eventLocation: eventLocationController.text,
      bookingType: isSeatBooking ? 'seat' : 'ticket',
      images: [...existingImageUrls, ...selectedImages.map((e) => e.path)],
      ticketPrice: double.parse(priceController.text),
      createdBy: widget.event.createdBy,
      layout: widget.event.layout,
      createdAt: widget.event.createdAt,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, updatedEvent);
  }
}
