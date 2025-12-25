import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';

import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class AROverlayScreen extends StatefulWidget {
  final File carPartImage;

  const AROverlayScreen({Key? key, required this.carPartImage})
    : super(key: key);

  @override
  State<AROverlayScreen> createState() => _AROverlayScreenState();
}

class _AROverlayScreenState extends State<AROverlayScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Overlay positioning variables
  double _overlayX = 0.0;
  double _overlayY = 0.0;
  double _overlayScale = 1.0;
  double _overlayRotation = 0.0;
  bool _showOverlay = true;
  double _opacity = 1.0; // New: Opacity control

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final permissionStatus = await Permission.camera.request();

      if (permissionStatus != PermissionStatus.granted) {
        setState(() {
          _errorMessage =
              'Camera permission denied. Please grant camera permission to use AR features.';
        });
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available on this device.';
        });
        return;
      }

      // Initialize camera controller with back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Widget _buildOverlayImage() {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 + _overlayX - 100,
      top: MediaQuery.of(context).size.height / 2 + _overlayY - 100,
      child: GestureDetector(
        // Enhanced: Add gesture controls for better UX
        onPanUpdate: (details) {
          setState(() {
            _overlayX += details.delta.dx;
            _overlayY += details.delta.dy;
          });
        },
        child: Transform.scale(
          scale: _overlayScale,
          child: Transform.rotate(
            angle: _overlayRotation,
            child: Opacity(
              opacity: _opacity,
              child: SizedBox(
                width: 200,
                height: 200,
                child: Image.file(
                  widget.carPartImage,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resetOverlayPosition() {
    setState(() {
      _overlayX = 0.0;
      _overlayY = 0.0;
      _overlayScale = 1.0;
      _overlayRotation = 0.0;
      _opacity = 1.0;
    });
  }

  void _adjustOverlayScale(double delta) {
    setState(() {
      _overlayScale = (_overlayScale + delta).clamp(0.2, 3.0);
    });
  }

  void _rotateOverlay(double angle) {
    setState(() {
      _overlayRotation += angle;
    });
  }

  Future<void> _takeScreenshot() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Saving to gallery...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save directly to gallery using Gal
      final String fileName =
          'AR_CarPart_${DateTime.now().millisecondsSinceEpoch}.png';
      await Gal.putImageBytes(pngBytes, name: fileName);

      // Success - Gal.putImageBytes completed without exception
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AR screenshot saved to Photos!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OPEN PHOTOS',
              textColor: Colors.white,
              onPressed: () async {
                await Gal.open();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showControlsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.withValues(alpha: 0.4),
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppSizes.cardBorderRadius(context)),
              topRight: Radius.circular(AppSizes.cardBorderRadius(context)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: AppSizes.getScreenWidth(context) * 0.1,
                height: AppSizes.getScreenHeight(context) * 0.005,
                decoration: BoxDecoration(
                  color: AppColors.foregroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSizes.smallPadding(context) / 4),
                ),
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),

              // Title
              Text(
                'AR Controls',
                style: TextStyle(
                  fontSize: AppSizes.largeFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),

              // Opacity control slider
              Row(
                children: [
                  Icon(
                    Icons.opacity,
                    color: AppColors.foregroundColor,
                    size: AppSizes.mediumIconSize(context),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  Expanded(
                    child: Slider(
                      value: _opacity,
                      onChanged: (value) {
                        setState(() {
                          _opacity = value;
                        });
                        setModalState(() {});
                      },
                      min: 0.1,
                      max: 1.0,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.foregroundColor.withOpacity(0.3),
                    ),
                  ),
                  Text(
                    '${(_opacity * 100).round()}%',
                    style: TextStyle(
                      color: AppColors.foregroundColor,
                      fontSize: AppSizes.smallFontSize(context),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSizes.mediumSpacing(context)),

              // Scale and rotation controls
              Text(
                'Size & Rotation Controls',
                style: TextStyle(
                  fontSize: AppSizes.bodyFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.titleColor,
                ),
              ),
              SizedBox(height: AppSizes.smallSpacing(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(Icons.remove, () {
                    _adjustOverlayScale(-0.1);
                    setModalState(() {});
                  }, 'Scale Down'),
                  _buildControlButton(Icons.add, () {
                    _adjustOverlayScale(0.1);
                    setModalState(() {});
                  }, 'Scale Up'),
                  _buildControlButton(Icons.rotate_left, () {
                    _rotateOverlay(-0.1);
                    setModalState(() {});
                  }, 'Rotate Left'),
                  _buildControlButton(Icons.rotate_right, () {
                    _rotateOverlay(0.1);
                    setModalState(() {});
                  }, 'Rotate Right'),
                ],
              ),
              SizedBox(height: AppSizes.largePadding(context)),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _resetOverlayPosition();
                        setModalState(() {});
                      },
                      icon: Icon(
                        Icons.refresh,
                        size: AppSizes.smallIconSize(context),
                      ),
                      label: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: AppSizes.smallFontSize(context),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSizes.mediumPadding(context),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showOverlay = !_showOverlay;
                        });
                        setModalState(() {});
                      },
                      icon: Icon(
                        _showOverlay ? Icons.visibility_off : Icons.visibility,
                        size: AppSizes.smallIconSize(context),
                      ),
                      label: Text(
                        _showOverlay ? 'Hide' : 'Show',
                        style: TextStyle(
                          fontSize: AppSizes.smallFontSize(context),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSizes.mediumPadding(context),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet first
                        _takeScreenshot();
                      },
                      icon: Icon(
                        Icons.camera_alt,
                        size: AppSizes.smallIconSize(context),
                      ),
                      label: Text(
                        'Capture',
                        style: TextStyle(
                          fontSize: AppSizes.smallFontSize(context),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppSizes.mediumPadding(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: AppSizes.getScreenWidth(context) * 0.12,
        height: AppSizes.getScreenWidth(context) * 0.12,
        alignment: Alignment.center,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: AppColors.foregroundColor,
            size: AppSizes.mediumIconSize(context),
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            shape: CircleBorder(),
            padding: EdgeInsets.zero,
            minimumSize: Size(AppSizes.getScreenWidth(context) * 0.1, AppSizes.getScreenWidth(context) * 0.1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AR Car Part Overlay',
          style: TextStyle(color: AppColors.titleColor),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.titleColor,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.backgroundColor,
                  title: Text(
                    'How to Use AR View',
                    style: TextStyle(color: AppColors.titleColor),
                  ),
                  content: Text(
                    '• Drag the car part to move it around\n'
                    '• Tap the controls button (bottom-right) for more options\n'
                    '• Adjust position, size, and transparency\n'
                    '• Capture clean screenshots without controls',
                    style: TextStyle(color: AppColors.foregroundColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Got it',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Stack(
          children: [
            // Camera preview
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(child: CameraPreview(_cameraController!))
            else
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Initializing camera...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        ElevatedButton(
                          onPressed: _initializeCamera,
                          child: const Text('Retry'),
                        )
                      else
                        CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              ),

            // Car part overlay
            if (_isCameraInitialized && _showOverlay) _buildOverlayImage(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showControlsBottomSheet,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.settings, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
