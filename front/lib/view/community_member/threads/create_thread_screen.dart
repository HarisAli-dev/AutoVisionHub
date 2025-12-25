import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/controller/groups/thread_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:image_picker/image_picker.dart';

class CreateThreadScreen extends StatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isCreating = false;

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(context, 'Failed to pick image');
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _createThread() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final result = await ThreadController.createThread(
      topicName: _topicController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      imageFile: _selectedImage,
    );

    if (mounted) {
      setState(() => _isCreating = false);

      if (result.contains('success')) {
        CustomSnackbars.showSuccessSnackbar(context, result, 1);
        Navigator.pop(context, true);
      } else {
        CustomSnackbars.showErrorSnackbar(context, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Discussion',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        backgroundColor: AppColors.appBarColor,
        iconTheme: IconThemeData(color: AppColors.foregroundColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Start a New Discussion Thread',
                style: TextStyle(
                  fontSize: AppSizes.titleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
              SizedBox(height: AppSizes.smallSpacing(context)),
              Text(
                'Create a topic for community members to discuss. Only text messages are allowed in discussion threads.',
                style: TextStyle(
                  fontSize: AppSizes.subtitleFontSize(context),
                  color: AppColors.shadeColor,
                ),
              ),
              SizedBox(height: AppSizes.largeSpacing(context)),

              // Image upload section
              Text(
                'Thread Cover Image (Optional)',
                style: TextStyle(
                  fontSize: AppSizes.subtitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.titleColor,
                ),
              ),
              SizedBox(height: AppSizes.smallSpacing(context)),
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.shadeColor.withOpacity(0.5),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.shadeColor.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: AppSizes.smallSpacing(context)),
                        Text(
                          'Tap to add cover image',
                          style: TextStyle(
                            color: AppColors.shadeColor,
                            fontSize: AppSizes.subtitleFontSize(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: AppSizes.largeSpacing(context)),
              CustomWidgets.customTextFormField(
                controller: _topicController,
                label: 'Topic Name *',
                borderColor: AppColors.primary,
                textColor: AppColors.foregroundColor,
                fontsize: AppSizes.inputFontSize(context),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic name';
                  }
                  if (value.trim().length < 3) {
                    return 'Topic name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              CustomWidgets.customTextFormField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                borderColor: AppColors.primary,
                textColor: AppColors.foregroundColor,
                fontsize: AppSizes.inputFontSize(context),
                maxLine: 4,
              ),
              SizedBox(height: AppSizes.largeSpacing(context)),
              _isCreating
                  ? Center(child: CustomWidgets.circularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createThread,
                      style: CustomWidgets.elevatedButtonStyle(context),
                      child: Text(
                        'Create Discussion',
                        style: TextStyle(
                          fontSize: AppSizes.subtitleFontSize(context),
                          color: AppColors.foregroundColor,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
