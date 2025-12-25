import 'dart:convert';
import 'package:front/model/events/event_model.dart';
import 'package:front/model/events/ticket_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:flutter/material.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/events_manager/seating_visualizer_screen.dart';
import 'package:front/controller/events/event_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:front/services/event_reminder_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventDescriptionController =
      TextEditingController();
  final TextEditingController eventLocationController = TextEditingController();
  final TextEditingController totalTicketsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  bool isSeatBooking = true; // Default to seat booking
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<XFile> selectedImages = []; // List to store selected images
  DateTime? selectedDateTime; // Store selected date and time

  // Upload state tracking variables
  List<String> uploadedImageUrls = []; // Store uploaded URLs
  bool imagesUploaded = false; // Track if current images are uploaded
  bool isUploading = false; // Track upload progress
  int lastUploadedCount = 0; // Track how many images were last uploaded

  @override
  void dispose() {
    eventNameController.dispose();
    eventDescriptionController.dispose();
    eventLocationController.dispose();
    super.dispose();
  }

  // Helper method to check if images need to be uploaded
  bool _needsImageUpload() {
    return !imagesUploaded ||
        selectedImages.length != lastUploadedCount ||
        uploadedImageUrls.isEmpty;
  }

  // Helper method to upload images only when needed
  Future<List<String>> _getImageUrls() async {
    if (_needsImageUpload()) {
      setState(() {
        isUploading = true;
      });

      try {
        List<String> imagePaths = await EventController.uploadEventImages(
          selectedImages,
        );
        if (imagePaths.isNotEmpty) {
          setState(() {
            uploadedImageUrls = imagePaths;
            imagesUploaded = true;
            lastUploadedCount = selectedImages.length;
            isUploading = false;
          });
          return imagePaths;
        } else {
          setState(() {
            isUploading = false;
          });
          return [];
        }
      } catch (e) {
        setState(() {
          isUploading = false;
        });
        return [];
      }
    } else {
      // Return cached URLs
      return uploadedImageUrls;
    }
  }

  // Helper method to reset upload state when images change
  void _resetUploadState() {
    setState(() {
      imagesUploaded = false;
      uploadedImageUrls.clear();
      lastUploadedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //using custom text fields
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

              //create a dropdown button to choose ticket booking or seat booking
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: CustomWidgets.customInputDecoration(
                    label: 'Booking Type',
                    borderColor: AppColors.shadeColor,
                    obscureText: false,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ticket',
                      child: Text('Ticket Booking'),
                    ),
                    DropdownMenuItem(
                      value: 'seat',
                      child: Text('Seat Booking'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'ticket') {
                      setState(() {
                        isSeatBooking = false;
                      });
                    } else {
                      setState(() {
                        isSeatBooking = true;
                      });
                    }
                  },
                ),
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
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
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
              isSeatBooking
                  ? const SizedBox()
                  : CustomWidgets.customTextFormField(
                      controller: totalTicketsController,
                      label: 'Total Event Tickets',
                      borderColor: AppColors.shadeColor,
                      textColor: AppColors.foregroundColor,
                      fontsize: AppSizes.inputFontSize(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter total event tickets';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          if (selectedDateTime == null) {
                            CustomSnackbars.showErrorSnackbar(
                              context,
                              'Please select event date and time',
                  
                            );
                            return;
                          }
                          if (selectedImages.isEmpty) {
                            CustomSnackbars.showErrorSnackbar(
                              context,
                              'Please select at least one event image',
         
                            );
                            return;
                          }

                          // Get image URLs (will upload only if needed)
                          List<String> imagePaths = await _getImageUrls();
                          if (imagePaths.isEmpty) {
                            CustomSnackbars.showErrorSnackbar(
                              context,
                              'Failed to upload event images',
          
                            );
                            return;
                          }

                          if (isSeatBooking) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeatingDesignerScreen(
                                  eventName: eventNameController.text,
                                  images: imagePaths,
                                  eventDescription:
                                      eventDescriptionController.text,
                                  dateTime: selectedDateTime!,
                                  eventLocation: eventLocationController.text,
                                  ticketPrice: double.parse(
                                    priceController.text,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            final response =
                                await EventController.createEventWithTickets(
                                  eventName: eventNameController.text,
                                  images: imagePaths,
                                  eventDescription:
                                      eventDescriptionController.text,
                                  eventDateTime: selectedDateTime!,
                                  eventLocation: eventLocationController.text,
                                  ticketPrice: double.parse(
                                    priceController.text,
                                  ),
                                  totalTickets: List.generate(
                                    int.parse(totalTicketsController.text),
                                    (index) => TicketModel.empty(index + 1),
                                  ),
                                );
                            if (response.statusCode == 200) {
                              try {
                                final Map<String, dynamic> body =
                                    jsonDecode(response.body);
                                if (body['data'] != null) {
                                  final EventModel event =
                                      EventModel.fromJson(body['data']);
                                  await EventReminderService
                                      .scheduleEventReminders(
                                    event: event,
                                    bookingSummary: 'Created by you.',
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  'Failed to schedule reminder for created event: $e',
                                );
                              }
                            }
                            Navigator.pop(
                              context,
                            ); // Go back to previous screen
                            CustomSnackbars.showSuccessSnackbar(
                              context,
                              'Event created successfully',
                              2.0,
                            );
                          }
                        }
                      },
                style: CustomWidgets.elevatedButtonStyle(context),
                child: isUploading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CustomWidgets.circularProgressIndicator(strokeWidth: 2.0),
                          ),
                        ],
                      )
                    : Text(
                        isSeatBooking ? 'Design Event seats' : 'Create Event',
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
      initialDate: DateTime.now(),
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
        initialTime: TimeOfDay.now(),
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

  // Build image selector widget
  Widget _buildImageSelector() {
    return SizedBox(
      height: AppSizes.getScreenHeight(context) * 0.12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: selectedImages.length + 1, // +1 for the add button
        itemBuilder: (context, index) {
          if (index == selectedImages.length) {
            // Add image button
            return _buildAddImageButton();
          } else {
            // Display selected image
            return _buildImagePreview(selectedImages[index], index);
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

  // Build image preview with remove option
  Widget _buildImagePreview(XFile image, int index) {
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
          // Upload status indicator
          if (imagesUploaded && index < lastUploadedCount)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.successColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_done,
                  size: AppSizes.getScreenWidth(context) * 0.04,
                  color: Colors.white,
                ),
              ),
            ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
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
      _resetUploadState(); // Reset upload state when new images are added
    }
  }

  // Pick image from camera
  void _pickImageFromCamera() async {
    final XFile? image = await EventController.pickImageFromCamera();
    if (image != null) {
      setState(() {
        selectedImages.add(image);
      });
      _resetUploadState(); // Reset upload state when new image is added
    }
  }

  // Remove image from selection
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
    _resetUploadState(); // Reset upload state when image is removed
  }
}
