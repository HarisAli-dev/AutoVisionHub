import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';

class EditListingScreen extends StatefulWidget {
  final ListingModel listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _brandController;
  late TextEditingController _yearController;
  late TextEditingController _mileageController;
  late TextEditingController _colorController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;

  late String _selectedCategory;
  late String _selectedSubcategory;
  late String _selectedCondition;
  late String _selectedFuelType;
  late String _selectedTransmission;

  // Existing image URLs from the listing
  List<String> _existingImageUrls = [];
  // New images picked by user
  List<File> _newImages = [];
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
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final listing = widget.listing;

    _titleController = TextEditingController(text: listing.title);
    _descriptionController = TextEditingController(text: listing.description);
    _priceController = TextEditingController(text: listing.price.toString());
    _quantityController = TextEditingController(
      text: listing.quantity.toString(),
    );
    _brandController = TextEditingController(text: listing.brand);
    _yearController = TextEditingController(
      text: listing.year?.toString() ?? '',
    );
    _mileageController = TextEditingController(
      text: listing.mileage?.toString() ?? '',
    );
    _colorController = TextEditingController(text: listing.color ?? '');
    _cityController = TextEditingController(text: listing.location.city);
    _addressController = TextEditingController(
      text: listing.location.address ?? '',
    );

    _selectedCategory = listing.category;
    _selectedSubcategory = listing.subcategory ?? '';
    _selectedCondition = listing.condition;
    _selectedFuelType = listing.fuelType ?? 'petrol';
    _selectedTransmission = listing.transmission ?? 'manual';

    _existingImageUrls = List.from(listing.images);
  }

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
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final totalImages = _existingImageUrls.length + _newImages.length;
      if (totalImages >= 5) {
        CustomSnackbars.showInfoSnackbar(
          context,
          'Maximum 5 images allowed',
          3.0,
        );
        return;
      }

      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 5 - totalImages;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        setState(() {
          for (var file in filesToAdd) {
            _newImages.add(File(file.path));
          }
        });

        if (pickedFiles.length > remainingSlots) {
          CustomSnackbars.showInfoSnackbar(
            context,
            'Maximum 5 images allowed. Added ${filesToAdd.length} images.',
            3.0,
          );
        }
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(context, 'Error picking images: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages == 0) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please add at least one image',
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CustomWidgets.circularProgressIndicator()),
    );

    try {
      // Upload new images to Cloudinary
      List<String> newImageUrls = [];
      if (_newImages.isNotEmpty) {
        CustomSnackbars.showInfoSnackbar(
          context,
          'Uploading ${_newImages.length} new image(s)...',
          3.0,
        );

        for (var imageFile in _newImages) {
          final result = await CloudinaryService.uploadFile(
            file: imageFile,
            fileType: 'image',
          );
          if (result['success'] == true) {
            newImageUrls.add(result['url']);
          }
        }
      }

      // Combine existing and new image URLs
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      // Prepare update data
      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'condition': _selectedCondition,
        'brand': _brandController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'images': allImageUrls,
      };

      // Add optional fields
      if (_yearController.text.isNotEmpty) {
        updateData['year'] = int.parse(_yearController.text);
      }
      if (_mileageController.text.isNotEmpty) {
        updateData['mileage'] = int.parse(_mileageController.text);
      }
      if (_colorController.text.isNotEmpty) {
        updateData['color'] = _colorController.text.trim();
      }
      if (_selectedCategory == 'vehicle') {
        updateData['fuelType'] = _selectedFuelType;
        updateData['transmission'] = _selectedTransmission;
      }

      // Update listing using the controller
      final controller = Provider.of<MarketplaceController>(
        context,
        listen: false,
      );

      await controller.updateListing(widget.listing.id!, updateData);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Close edit screen
      Navigator.pop(context, true);

      CustomSnackbars.showSuccessSnackbar(
        context,
        'Listing updated successfully!',
        3.0,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      CustomSnackbars.showErrorSnackbar(context, 'Error updating listing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
          children: [
            // Images Section
            _buildImagesSection(),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Enter listing title',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your item',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Price
            _buildTextField(
              controller: _priceController,
              label: 'Price',
              hint: 'Enter price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Quantity
            _buildTextField(
              controller: _quantityController,
              label: 'Quantity',
              hint: 'Enter quantity',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                return null;
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Condition
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value!;
                });
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Brand
            _buildTextField(
              controller: _brandController,
              label: 'Brand',
              hint: 'Enter brand name',
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Vehicle-specific fields
            if (_selectedCategory == 'vehicle') ...[
              _buildTextField(
                controller: _yearController,
                label: 'Year',
                hint: 'Enter year',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),

              _buildTextField(
                controller: _mileageController,
                label: 'Mileage (km)',
                hint: 'Enter mileage',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),

              DropdownButtonFormField<String>(
                value: _selectedFuelType,
                decoration: const InputDecoration(
                  labelText: 'Fuel Type',
                  border: OutlineInputBorder(),
                ),
                items: _fuelTypes.map((fuel) {
                  return DropdownMenuItem(value: fuel, child: Text(fuel));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFuelType = value!;
                  });
                },
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),

              DropdownButtonFormField<String>(
                value: _selectedTransmission,
                decoration: const InputDecoration(
                  labelText: 'Transmission',
                  border: OutlineInputBorder(),
                ),
                items: _transmissions.map((trans) {
                  return DropdownMenuItem(value: trans, child: Text(trans));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTransmission = value!;
                  });
                },
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
            ],

            // Color
            _buildTextField(
              controller: _colorController,
              label: 'Color',
              hint: 'Enter color',
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // City
            _buildTextField(
              controller: _cityController,
              label: 'City',
              hint: 'Enter city',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter city';
                }
                return null;
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Address
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'Enter address',
              maxLines: 2,
            ),
            SizedBox(height: AppSizes.largeSpacing(context)),

            // Update Button
            ElevatedButton(
              onPressed: _updateListing,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Update Listing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    final totalImages = _existingImageUrls.length + _newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$totalImages/5',
              style: TextStyle(
                color: totalImages >= 5 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Display existing images
        if (_existingImageUrls.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _existingImageUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value;
              return _buildExistingImageTile(imageUrl, index);
            }).toList(),
          ),

        // Display new images
        if (_newImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _newImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageFile = entry.value;
              return _buildNewImageTile(imageFile, index);
            }).toList(),
          ),

        const SizedBox(height: 12),

        // Add Image Button
        if (totalImages < 5)
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Images'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return CustomWidgets.customTextFormField(
      controller: controller,
      label: label,
      borderColor: AppColors.primary,
      textColor: AppColors.foregroundColor,
      fontsize: AppSizes.inputFontSize(context),
      maxLine: maxLines,
      isnumber: keyboardType == TextInputType.number,
      isphone: keyboardType == TextInputType.phone,
      validator: validator,
    );
  }

  Widget _buildExistingImageTile(String imageUrl, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeExistingImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageTile(File imageFile, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: FileImage(imageFile),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeNewImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
