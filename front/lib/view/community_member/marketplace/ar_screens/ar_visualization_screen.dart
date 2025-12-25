import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/config/app_config.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:http/http.dart' as http;
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/community_member/marketplace/ar_screens/ar_overlay_screen.dart';

class ARVisualizationScreen extends StatefulWidget {
  final ListingModel listing;

  const ARVisualizationScreen({
    super.key,
    required this.listing,
  });

  @override
  State<ARVisualizationScreen> createState() => _ARVisualizationScreenState();
}

class _ARVisualizationScreenState extends State<ARVisualizationScreen> {

  static String apiUrl = AppConfig.bgRemoverApiUrl;
  
  String? selectedImageUrl;
  bool isProcessing = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'AR Visualization',
          style: TextStyle(color: AppColors.titleColor),
        ),
        backgroundColor: AppColors.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: AppColors.backgroundColor,
              child: Padding(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                child: Column(
                  children: [
                    Icon(
                      Icons.view_in_ar,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    Text(
                      'AR Part Visualization',
                      style: TextStyle(
                        fontSize: AppSizes.subtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                    SizedBox(height: AppSizes.smallSpacing(context)),
                    Text(
                      'Select an image of the part to visualize it in AR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSizes.bodyFontSize(context),
                        color: AppColors.shadeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Image Selection
            Text(
              'Select Part Image',
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Image Grid
            if (widget.listing.images.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.mediumSpacing(context),
                  mainAxisSpacing: AppSizes.mediumSpacing(context),
                  childAspectRatio: 1,
                ),
                itemCount: widget.listing.images.length,
                itemBuilder: (context, index) {
                  final imageUrl = widget.listing.images[index];
                  final isSelected = selectedImageUrl == imageUrl;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImageUrl = imageUrl;
                        errorMessage = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius(context),
                        ),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primary 
                              : AppColors.shadeColor.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius(context),
                        ),
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.shadeColor.withOpacity(0.1),
                                  child: Center(
                                    child: Icon(
                                      Icons.error,
                                      color: AppColors.shadeColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.shadeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppSizes.cardBorderRadius(context),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No images available',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                ),
              ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Error Message
            if (errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(
                    AppSizes.cardBorderRadius(context),
                  ),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: AppSizes.smallSpacing(context)),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
            ],

            // Process Button
            ElevatedButton.icon(
              onPressed: selectedImageUrl != null && !isProcessing
                  ? _processImageAndStartAR
                  : null,
              icon: isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomWidgets.circularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.auto_fix_high),
              label: Text(
                isProcessing ? 'Processing...' : 'Start AR Visualization',
                style: TextStyle(fontSize: AppSizes.inputFontSize(context)),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: AppSizes.mediumSpacing(context),
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Steps indicator
            Card(
              color: AppColors.backgroundColor,
              child: Padding(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(
                        fontSize: AppSizes.bodyFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                    SizedBox(height: AppSizes.smallSpacing(context)),
                    _buildStep(1, 'Select an image from the part gallery'),
                    _buildStep(2, 'AI removes the background automatically'),
                    _buildStep(3, 'View the part in AR through your camera'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.smallSpacing(context)),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSizes.mediumSpacing(context)),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.smallFontSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImageAndStartAR() async {
    if (selectedImageUrl == null) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      // Download the image first
      final response = await http.get(Uri.parse(selectedImageUrl!));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Create multipart request for background removal
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/remove-background'),
      );

      // Add image data to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          response.bodyBytes,
          filename: 'part_image.jpg',
        ),
      );

      var apiResponse = await request.send();

      if (apiResponse.statusCode == 200) {
        var responseData = await apiResponse.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (jsonResponse['success'] == true) {
          // Decode base64 image
          var imageBytes = base64.decode(jsonResponse['image']);

          // Save to temp file
          var tempDir = Directory.systemTemp;
          var timestamp = DateTime.now().millisecondsSinceEpoch;
          var tempFile = File('${tempDir.path}/ar_part_$timestamp.png');
          await tempFile.writeAsBytes(imageBytes);

          setState(() {
            isProcessing = false;
          });

          // Navigate to AR overlay screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AROverlayScreen(carPartImage: tempFile),
            ),
          );
        } else {
          throw Exception(jsonResponse['error'] ?? 'Background removal failed');
        }
      } else {
        throw Exception('Server error: ${apiResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error processing image: $e';
        isProcessing = false;
      });
    }
  }
}