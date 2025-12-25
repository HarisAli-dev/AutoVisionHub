import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _brandController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _colorController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _startingBidController = TextEditingController();
  final _bidIncrementController = TextEditingController();

  String _selectedCategory = 'vehicle';
  String _selectedSubcategory = '';
  String _selectedCondition = 'excellent';
  String _selectedFuelType = 'petrol';
  String _selectedTransmission = 'manual';
  bool _isAuction = false;
  DateTime? _auctionEndTime;

  // Image upload state
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = ['vehicle', 'part', 'accessory'];
  final List<String> _conditions = ['excellent', 'good', 'fair', 'poor'];
  final List<String> _fuelTypes = [
    'petrol',
    'diesel',
    'hybrid',
    'electric',
    'cng',
  ];
  final List<String> _transmissions = ['manual', 'automatic', 'cvt'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _colorController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _startingBidController.dispose();
    _bidIncrementController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        // Limit to 5 images total
        final remainingSlots = 5 - _selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        setState(() {
          for (var file in filesToAdd) {
            _selectedImages.add(File(file.path));
          }
        });

        if (pickedFiles.length > remainingSlots) {
          CustomSnackbars.showInfoSnackbar(
            context,
            'Maximum 5 images allowed. Added ${filesToAdd.length} images.',
            3.0,
          );
        }

        // Don't automatically upload - just show success message
        CustomSnackbars.showSuccessSnackbar(
          context,
          '${filesToAdd.length} image(s) selected',
          2.0,
        );
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(context, 'Error picking images: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (_selectedImages.length >= 5) {
        CustomSnackbars.showInfoSnackbar(
          context,
          'Maximum 5 images allowed',
          3.0,
        );
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });

        // Don't automatically upload - just show success message
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Image captured successfully',
          2.0,
        );
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(context, 'Error taking photo: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  _pickImages();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
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

  @override
  Widget build(BuildContext context) {
    // Initialize theme colors
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          'Create Listing',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              _buildImageUploadSection(),
              SizedBox(height: AppSizes.largeSpacing(context)),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              SizedBox(height: AppSizes.mediumSpacing(context)),

              _buildTextField(
                controller: _titleController,
                label: 'Product Title',
                hint: 'e.g., BMW E46 Side Mirrors',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your product in detail...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selection
              _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _selectedSubcategory = '';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Price
              _buildTextField(
                controller: _priceController,
                label: 'Price (PKR)',
                hint: 'Enter price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              _buildTextField(
                controller: _quantityController,
                label: 'Quantity/Stock',
                hint: 'Enter available quantity',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 1) {
                    return 'Please enter a valid quantity (minimum 1)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Condition
              _buildDropdown(
                label: 'Condition',
                value: _selectedCondition,
                items: _conditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Vehicle/Part Details
              if (_selectedCategory == 'vehicle') ...[
                _buildSectionTitle('Vehicle Details'),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _brandController,
                  label: 'Brand',
                  hint: 'e.g., Toyota',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter brand';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _yearController,
                        label: 'Year',
                        hint: '2020',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _mileageController,
                        label: 'Mileage (km)',
                        hint: '50000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Fuel Type',
                        value: _selectedFuelType,
                        items: _fuelTypes.map((fuel) {
                          return DropdownMenuItem(
                            value: fuel,
                            child: Text(fuel.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFuelType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Transmission',
                        value: _selectedTransmission,
                        items: _transmissions.map((transmission) {
                          return DropdownMenuItem(
                            value: transmission,
                            child: Text(transmission.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTransmission = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _colorController,
                  label: 'Color',
                  hint: 'e.g., White',
                ),
              ] else ...[
                _buildSectionTitle('Product Details'),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _brandController,
                  label: 'Brand',
                  hint: 'e.g., Apple',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter brand';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Location
              _buildSectionTitle('Location'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _cityController,
                label: 'City',
                hint: 'e.g., Karachi',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: 'Address (Optional)',
                hint: 'Enter your address',
              ),
              const SizedBox(height: 24),

              // Auction Settings
              _buildSectionTitle('Listing Type'),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text(
                  'Auction Listing',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Allow users to bid on your item',
                  style: TextStyle(color: Colors.grey),
                ),
                value: _isAuction,
                onChanged: (value) {
                  setState(() {
                    _isAuction = value;
                  });
                },
                activeColor: AppColors.primary,
              ),

              if (_isAuction) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: TextEditingController(
                    text: _auctionEndTime != null
                        ? '${_auctionEndTime!.day}/${_auctionEndTime!.month}/${_auctionEndTime!.year}'
                        : '',
                  ),
                  label: 'Auction End Date',
                  hint: 'Select end date',
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() {
                        _auctionEndTime = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _startingBidController,
                  label: 'Starting Bid (PKR)',
                  hint: 'Enter starting bid amount',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isAuction && (value == null || value.isEmpty)) {
                      return 'Starting bid is required for auction listings';
                    }
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bidIncrementController,
                  label: 'Bid Increment (PKR) - Optional',
                  hint: 'Minimum bid increase (default: 1000)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],

              SizedBox(height: AppSizes.largeSpacing(context)),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight(context),
                child: ElevatedButton(
                  onPressed: _submitListing,
                  style: CustomWidgets.elevatedButtonStyle(context),
                  child: Consumer<MarketplaceController>(
                    builder: (context, controller, child) {
                      return controller.isLoading
                          ? CircularProgressIndicator(
                              color: AppColors.titleColor,
                            )
                          : Text(
                              'Create Listing',
                              style: TextStyle(
                                color: AppColors.titleColor,
                                fontSize: AppSizes.inputFontSize(context),
                                fontWeight: FontWeight.bold,
                              ),
                            );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      height: AppSizes.imageHeight(context),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(
          color: AppColors.shadeColor,
          style: BorderStyle.solid,
        ),
      ),
      child: _selectedImages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: AppSizes.extraLargeIconSize(context),
                    color: AppColors.shadeColor,
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    'Upload Product Images',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.inputFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context) / 2),
                  Text(
                    'Up to 5 images • JPEG/PNG only',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.smallFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  ElevatedButton.icon(
                    onPressed: _showImagePickerBottomSheet,
                    icon: Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.titleColor,
                    ),
                    label: Text(
                      'Add Images',
                      style: TextStyle(color: AppColors.titleColor),
                    ),
                    style: CustomWidgets.elevatedButtonStyle(context),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Image Grid
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(AppSizes.smallPadding(context)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppSizes.smallSpacing(context),
                      mainAxisSpacing: AppSizes.smallSpacing(context),
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[800],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),

                          // Remove Button
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Bottom Actions
                Padding(
                  padding: EdgeInsets.all(AppSizes.smallPadding(context)),
                  child: Row(
                    children: [
                      if (_selectedImages.length < 5)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showImagePickerBottomSheet,
                            icon: Icon(
                              Icons.add_photo_alternate,
                              color: AppColors.titleColor,
                            ),
                            label: Text(
                              'Add More Images',
                              style: TextStyle(color: AppColors.titleColor),
                            ),
                            style: CustomWidgets.elevatedButtonStyle(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.titleColor,
        fontSize: AppSizes.subtitleFontSize(context),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomWidgets.customTextFormField(
        controller: controller,
        label: label,
        borderColor: AppColors.primary,
        textColor: AppColors.foregroundColor,
        fontsize: AppSizes.inputFontSize(context),
        maxLine: maxLines,
        disabled: readOnly,
        isnumber: keyboardType == TextInputType.number,
        isphone: keyboardType == TextInputType.phone,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: TextStyle(
        color: AppColors.foregroundColor,
        fontSize: AppSizes.inputFontSize(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.foregroundColor),
        filled: true,
        fillColor: AppColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputBorderRadius(context),
          ),
          borderSide: BorderSide(color: AppColors.foregroundColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputBorderRadius(context),
          ),
          borderSide: BorderSide(color: AppColors.foregroundColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputBorderRadius(context),
          ),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      dropdownColor: AppColors.backgroundColor,
      items: items,
      onChanged: onChanged,
    );
  }

  void _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please select at least one image',
      );
      return;
    }

    if (_isAuction && _auctionEndTime == null) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please select auction end date',
      );
      return;
    }

    if (_isAuction && _startingBidController.text.isEmpty) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please enter starting bid for auction',
      );
      return;
    }

    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

    // Show uploading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Uploading images and creating listing...',
                style: TextStyle(color: AppColors.foregroundColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    try {
      // Upload images first
      List<String> uploadedUrls = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];

        final result = await CloudinaryService.uploadFile(
          file: file,
          fileType: 'image',
        );

        if (result['success'] == true) {
          uploadedUrls.add(result['url']);
        } else {
          throw Exception('Failed to upload image ${i + 1}');
        }
      }

      // Debug: Check if we have images and form data
      print('=== CREATE LISTING DEBUG ===');
      print('Title: ${_titleController.text}');
      print('Description: ${_descriptionController.text}');
      print('Price: ${_priceController.text}');
      print('Images count: ${uploadedUrls.length}');
      print('Images URLs: $uploadedUrls');
      print('Category: $_selectedCategory');
      print('Brand: ${_brandController.text}');
      print('============================');

      final listingData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'brand': _brandController.text.trim(),
        'year': _yearController.text.isNotEmpty
            ? int.parse(_yearController.text)
            : null,
        'condition': _selectedCondition,
        'mileage': _mileageController.text.isNotEmpty
            ? int.parse(_mileageController.text)
            : null,
        'fuelType': _selectedCategory == 'vehicle' ? _selectedFuelType : null,
        'transmission': _selectedCategory == 'vehicle'
            ? _selectedTransmission
            : null,
        'color': _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        'images': uploadedUrls, // Use uploaded Cloudinary URLs
        'location': {
          'city': _cityController.text.trim(),
          'address': _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        },
        'isAuction': _isAuction,
        'auctionEndTime': _auctionEndTime?.toIso8601String(),
        'startingBid': _isAuction && _startingBidController.text.isNotEmpty
            ? double.parse(_startingBidController.text)
            : null,
        'bidIncrement': _bidIncrementController.text.isNotEmpty
            ? double.parse(_bidIncrementController.text)
            : null,
      };

      final success = await controller.createListing(listingData);

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Listing created successfully!',
          2.0,
        );
        Navigator.pop(context);
      } else {
        CustomSnackbars.showErrorSnackbar(
          context,
          controller.error ?? 'Failed to create listing',
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      CustomSnackbars.showErrorSnackbar(context, 'Error: $e');
    }
  }
}
