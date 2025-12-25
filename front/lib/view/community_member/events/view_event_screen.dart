import 'dart:async';
import 'package:flutter/material.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/community_member/events/seat_booking_screen.dart';
import 'package:front/view/community_member/events/ticket_booking_screen.dart';
import 'package:front/services/live_stream_service.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/time_utils.dart';

class ViewEventScreen extends StatefulWidget {
  final EventModel event;

  const ViewEventScreen({super.key, required this.event});

  @override
  State<ViewEventScreen> createState() => _ViewEventScreenState();
}

class _ViewEventScreenState extends State<ViewEventScreen> {
  int _currentImageIndex = 0;
  Timer? _timer;
  List<String> images = [];

  // Live stream related variables
  bool _isCheckingLiveStream = false;
  Map<String, dynamic>? _liveStreamStatus;
  Timer? _liveStreamTimer;

  @override
  void initState() {
    super.initState();
    _startImageSlideshow();
    _getImages();
    _checkLiveStreamStatus();
    _startLiveStreamStatusPolling();
  }

  void _getImages() {
    images = widget.event.images;
  }

  void _startImageSlideshow() {
    if (widget.event.images.length > 2) {
      // Only auto-advance if 3+ images
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_currentImageIndex < widget.event.images.length - 1) {
          _currentImageIndex++;
        } else {
          _currentImageIndex = 0;
        }
        setState(() {}); // Update the UI for Netflix-style slideshow
      });
    }
  }

  // Helper methods for Netflix-style slideshow
  int _getPreviousIndex() {
    return _currentImageIndex == 0
        ? widget.event.images.length - 1
        : _currentImageIndex - 1;
  }

  int _getNextIndex() {
    return _currentImageIndex == widget.event.images.length - 1
        ? 0
        : _currentImageIndex + 1;
  }

  void _goToPrevious() {
    setState(() {
      _currentImageIndex = _getPreviousIndex();
    });
  }

  void _goToNext() {
    setState(() {
      _currentImageIndex = _getNextIndex();
    });
  }

  void _showFullScreenImage({int? imageIndex}) {
    final int indexToShow = imageIndex ?? _currentImageIndex;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${indexToShow + 1} of ${widget.event.images.length}',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: indexToShow),
            itemCount: widget.event.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    widget.event.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.white, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _liveStreamTimer?.cancel();
    super.dispose();
  }

  // Live stream methods
  Future<void> _checkLiveStreamStatus() async {
    if (widget.event.id == null) return;

    setState(() {
      _isCheckingLiveStream = true;
    });

    try {
      final status = await LiveStreamService.getLiveStreamStatus(
        widget.event.id!,
      );
      if (mounted) {
        setState(() {
          _liveStreamStatus = status;
          _isCheckingLiveStream = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLiveStream = false;
        });
      }
    }
  }

  void _startLiveStreamStatusPolling() {
    // Check live stream status every 30 seconds
    _liveStreamTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkLiveStreamStatus();
    });
  }

  void _navigateToLiveStream() async {
    if (_liveStreamStatus == null || _liveStreamStatus!['roomId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Live stream is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Join the live stream first
    final success = await LiveStreamService.joinLiveStream(
      _liveStreamStatus!['roomId'],
    );

    if (success) {
      // Join Socket.IO room for real-time events
      final socketService = SocketService();
      if (!socketService.isConnected) {
        socketService.init();
      }
      socketService.joinLiveStreamRoom(_liveStreamStatus!['roomId']);

      // Navigate directly to Zego live streaming
      LiveStreamService.navigateToAudienceLiveStream(
        context: context,
        roomId: _liveStreamStatus!['roomId'],
        event: widget.event,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join live stream'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.event.eventName,
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context),
            color: AppColors.foregroundColor,
          ),
        ),
        backgroundColor: AppColors.appBarColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foregroundColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slideshow
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: _buildImageSlideshow(),
            ),

            // Event Details
            Padding(
              padding: EdgeInsets.all(AppSizes.getScreenWidth(context) * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    widget.event.eventName,
                    style: TextStyle(
                      fontSize: AppSizes.titleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: AppColors.foregroundColor,
                    ),
                  ),
                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),

                  // Description Section
                  _buildSectionTitle('Description'),
                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.01),
                  Text(
                    widget.event.eventDescription,
                    style: TextStyle(
                      fontSize: AppSizes.bodyFontSize(context),
                      color: AppColors.foregroundColor,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.03),

                  // Event Details Section
                  _buildSectionTitle('Event Details'),
                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),

                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    TimeUtils.formatDatePKT(widget.event.eventDateTime),
                  ),
                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.015),

                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    TimeUtils.formatTimePKT(widget.event.eventDateTime),
                  ),
                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.015),

                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    widget.event.eventLocation,
                  ),
                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.015),

                  _buildDetailRow(
                    Icons.confirmation_number,
                    'Booking Type',
                    widget.event.bookingType == 'seat'
                        ? 'Seat Booking'
                        : 'Ticket Booking',
                  ),

                  if (widget.event.ticketPrice > 0) ...[
                    SizedBox(height: AppSizes.getScreenHeight(context) * 0.015),
                    _buildDetailRow(
                      Icons.attach_money,
                      'Price',
                      'RS ${widget.event.ticketPrice.toStringAsFixed(0)}',
                    ),
                  ],

                  SizedBox(height: AppSizes.getScreenHeight(context) * 0.04),

                  // Live Stream Button (if active)
                  if (_liveStreamStatus != null &&
                      _liveStreamStatus!['isActive'] == true)
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: AppSizes.getScreenHeight(context) * 0.06,
                          child: ElevatedButton.icon(
                            onPressed: _navigateToLiveStream,
                            icon: Icon(Icons.live_tv, color: Colors.white),
                            label: Text(
                              'Watch Live Stream',
                              style: TextStyle(
                                fontSize: AppSizes.subtitleFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.getScreenWidth(context) * 0.03,
                                ),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: AppSizes.getScreenHeight(context) * 0.02,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'LIVE - ${_liveStreamStatus!['status']?['viewerCount'] ?? 0} viewers',
                              style: TextStyle(
                                fontSize: AppSizes.bodyFontSize(context),
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: AppSizes.getScreenHeight(context) * 0.02,
                        ),
                      ],
                    ),

                  // Book Button
                  _buildBookButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlideshow() {
    // Handle different image counts
    if (widget.event.images.isEmpty) {
      return Container(
        height: AppSizes.getScreenHeight(context) * 0.3,
        decoration: BoxDecoration(
          color: AppColors.shadeColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: AppColors.shadeColor,
              ),
              SizedBox(height: 8),
              Text(
                'No images available',
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

    if (widget.event.images.length == 1) {
      return _buildSingleImage();
    }

    if (widget.event.images.length == 2) {
      return _buildTwoImages();
    }

    return _buildMultipleImages();
  }

  Widget _buildSingleImage() {
    return Container(
      height: AppSizes.getScreenHeight(context) * 0.3,
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(imageIndex: 0),
            child: Image.network(
              widget.event.images[0],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages() {
    return Container(
      height: AppSizes.getScreenHeight(context) * 0.3,
      child: Stack(
        children: [
          Row(
            children: [
              // First image
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showFullScreenImage(imageIndex: 0);
                  },
                  onLongPress: () {
                    setState(() {
                      _currentImageIndex = 0;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 100),
                    margin: EdgeInsets.all(_currentImageIndex == 0 ? 8 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _currentImageIndex == 0
                              ? Colors.black38
                              : Colors.black26,
                          blurRadius: _currentImageIndex == 0 ? 12 : 8,
                          offset: Offset(0, _currentImageIndex == 0 ? 6 : 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColorFiltered(
                        colorFilter: _currentImageIndex == 0
                            ? ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              )
                            : ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken,
                              ),
                        child: Image.network(
                          widget.event.images[0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Second image
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showFullScreenImage(imageIndex: 1);
                  },
                  onLongPress: () {
                    setState(() {
                      _currentImageIndex = 1;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.all(_currentImageIndex == 1 ? 8 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _currentImageIndex == 1
                              ? Colors.black38
                              : Colors.black26,
                          blurRadius: _currentImageIndex == 1 ? 12 : 8,
                          offset: Offset(0, _currentImageIndex == 1 ? 6 : 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColorFiltered(
                        colorFilter: _currentImageIndex == 1
                            ? ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              )
                            : ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken,
                              ),
                        child: Image.network(
                          widget.event.images[1],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Indicators for two images
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: _currentImageIndex == index ? 12 : 8,
                  height: _currentImageIndex == index ? 12 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? AppColors.primary
                        : AppColors.shadeColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleImages() {
    return Container(
      height: AppSizes.getScreenHeight(context) * 0.3,
      child: Stack(
        children: [
          // Netflix-style slideshow with smooth animations
          Row(
            children: [
              // Left side image (previous) - smaller
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(imageIndex: _getPreviousIndex()),
                  onLongPress: () => _goToPrevious(),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.fromLTRB(8, 24, 4, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4),
                          BlendMode.darken,
                        ),
                        child: Image.network(
                          widget.event.images[_getPreviousIndex()],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Center main image - larger
              Expanded(
                flex: 5, // Increased from 4 to 5 to make it larger
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.fromLTRB(
                      4,
                      8,
                      4,
                      8,
                    ), // Smaller margins for larger image
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.event.images[_currentImageIndex],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),

              // Right side image (next) - smaller
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(imageIndex: _getNextIndex()),
                  onLongPress: () => _goToNext(),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.fromLTRB(4, 24, 8, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4),
                          BlendMode.darken,
                        ),
                        child: Image.network(
                          widget.event.images[_getNextIndex()],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Image indicators with animation
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.event.images.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: _currentImageIndex == index ? 12 : 8,
                  height: _currentImageIndex == index ? 12 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? AppColors.primary
                        : AppColors.shadeColor,
                  ),
                ),
              ),
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
        fontSize: AppSizes.subtitleFontSize(context),
        fontWeight: FontWeight.bold,
        color: AppColors.foregroundColor,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppSizes.getScreenWidth(context) * 0.05,
          color: AppColors.primary,
        ),
        SizedBox(width: AppSizes.getScreenWidth(context) * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.bodyFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.shadeColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppSizes.bodyFontSize(context),
                  color: AppColors.foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      height: AppSizes.getScreenHeight(context) * 0.06,
      child: ElevatedButton(
        onPressed: () async {
          if (widget.event.bookingType == 'seat') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeatBookingScreen(
                  event: widget.event,
                  layoutName: widget.event.layout!.layoutName,
                  gridHeight: widget.event.layout!.gridHeight,
                  gridWidth: widget.event.layout!.gridWidth,
                  seats: widget.event.layout!.seatList,
                ),
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketBookingScreen(event: widget.event),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSizes.getScreenWidth(context) * 0.03,
            ),
          ),
          elevation: 2,
        ),
        child: Text(
          'Book Now',
          style: TextStyle(
            fontSize: AppSizes.subtitleFontSize(context),
            fontWeight: FontWeight.bold,
            color: AppColors.foregroundColor,
          ),
        ),
      ),
    );
  }
}
