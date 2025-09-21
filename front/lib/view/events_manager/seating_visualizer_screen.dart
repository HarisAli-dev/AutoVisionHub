import 'dart:math' as math;
import 'dart:ui';
import 'package:front/controller/events/event_controller.dart';
import 'package:front/model/events/layout_model.dart';
import 'package:front/model/events/seats_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:flutter/material.dart';
import 'package:front/utils/snackbars.dart';

// The screen containing the seating designer
// ignore: must_be_immutable
class SeatingDesignerScreen extends StatefulWidget {
  final String eventName;
  final String eventDescription;
  final List<String> images;
  final DateTime dateTime;
  final String eventLocation;
  final double ticketPrice;
  LayoutModel? seatingLayout;

  SeatingDesignerScreen({
    super.key,
    required this.eventName,
    required this.eventDescription,
    required this.images,
    required this.dateTime,
    required this.eventLocation,
    required this.ticketPrice,
    this.seatingLayout,
  });

  @override
  State<SeatingDesignerScreen> createState() => _SeatingDesignerScreenState();
}

class _SeatingDesignerScreenState extends State<SeatingDesignerScreen> {
  final TextEditingController _layoutNameController = TextEditingController();

  double _gridSize = 40.0;

  final TransformationController _transformationController =
      TransformationController();

  static const int _minGridDimension = 5;
  static const int _maxGridDimension = 50;

  @override
  void initState() {
    super.initState();
    // Initialize layout with default values
    if (widget.seatingLayout == null) {
      widget.seatingLayout = LayoutModel(
        layoutName: '',
        gridWidth: 5,
        gridHeight: 5,
        seatList: [],
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOptimalGridSize();
    });
  }

  @override
  void dispose() {
    _layoutNameController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _showDeleteSeatDialog(int seatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Seat?'),
        content: Text('Are you sure you want to delete seat ${seatId + 1}?'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: AppColors.primary)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            onPressed: () {
              setState(() {
                widget.seatingLayout?.removeSeatByNumber(seatId);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getSeatColor(SeatState state) {
    switch (state) {
      case SeatState.empty:
        return AppColors.seatEmptyColor;
      case SeatState.booked:
        return AppColors.seatBookedColor;
      case SeatState.reserved:
        return AppColors.seatReservedColor;
    }
  }

  void _calculateOptimalGridSize() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    final availableWidth = screenSize.width - 32;
    final availableHeight = screenSize.height - (kToolbarHeight + 64);
    final optimalWidthGridSize =
        availableWidth / widget.seatingLayout!.gridWidth;
    final optimalHeightGridSize =
        availableHeight / widget.seatingLayout!.gridHeight;
    final optimalGridSize = math.min(
      optimalWidthGridSize,
      optimalHeightGridSize,
    );
    setState(() {
      _gridSize = optimalGridSize.clamp(20.0, 60.0);
    });
  }

  void _expandGridHorizontally() {
    if (widget.seatingLayout!.gridWidth < _maxGridDimension) {
      setState(() {
        widget.seatingLayout!.gridWidth++;
        _calculateOptimalGridSize();
      });
    }
  }

  void _expandGridVertically() {
    if (widget.seatingLayout!.gridHeight < _maxGridDimension) {
      setState(() {
        widget.seatingLayout!.gridHeight++;
        _calculateOptimalGridSize();
      });
    }
  }

  void _shrinkGridHorizontally() {
    if (widget.seatingLayout!.gridWidth > _minGridDimension) {
      setState(() {
        widget.seatingLayout!.gridWidth--;
        _calculateOptimalGridSize();
      });
    }
  }

  void _shrinkGridVertically() {
    if (widget.seatingLayout!.gridHeight > _minGridDimension) {
      setState(() {
        widget.seatingLayout!.gridHeight--;
        _calculateOptimalGridSize();
      });
    }
  }

  void _saveEventToBackend(String layoutName) async {
    // Set the layout name before saving
    widget.seatingLayout!.layoutName = layoutName;
    await EventController.createEventWithLayout(
          eventName: widget.eventName,
          images: widget.images,
          eventDescription: widget.eventDescription,
          eventDateTime: widget.dateTime,
          eventLocation: widget.eventLocation,
          layout: widget.seatingLayout!,
          ticketPrice: widget.ticketPrice,
        )
        .then((response) {
          print("Response status: ${response.statusCode}");
          if (response.statusCode == 201) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event created successfully!')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to create event. Error: ${response.reasonPhrase}',
                ),
              ),
            );
          }
        })
        .catchError((error) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error occurred: $error')));
        });
  }

  bool _canShrinkGridHorizontally() {
    return widget.seatingLayout!.gridWidth > _minGridDimension &&
        !widget.seatingLayout!.seatList.any(
          (seat) => seat.gridX == widget.seatingLayout!.gridWidth - 1,
        );
  }

  bool _canShrinkGridVertically() {
    return widget.seatingLayout!.gridHeight > _minGridDimension &&
        !widget.seatingLayout!.seatList.any(
          (seat) => seat.gridY == widget.seatingLayout!.gridHeight - 1,
        );
  }

  void _showClearAllDialog() {
    if (widget.seatingLayout!.seatList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No seats to clear'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear All Seats?'),
        content: Text(
          'Are you sure you want to remove all ${widget.seatingLayout!.seatList.length} seats from the layout?',
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: AppColors.primary)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            onPressed: () {
              setState(() {
                widget.seatingLayout!.seatList.clear();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All seats cleared'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showLayoutNameDialog() {
    _layoutNameController.clear();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Layout Name'),
          content: CustomWidgets.customTextFormField(
            controller: _layoutNameController,
            label: 'Layout Name',
            borderColor: AppColors.primary,
            textColor: AppColors.foregroundColor,
            fontsize: AppSizes.bodyFontSize(context),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save', style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                widget.seatingLayout!.layoutName = _layoutNameController.text
                    .trim();
                print("Current Layout: ${widget.seatingLayout!}");
                if (widget.seatingLayout!.layoutName.isNotEmpty) {
                  _saveEventToBackend(widget.seatingLayout!.layoutName);
                  Navigator.of(context).pop(widget.seatingLayout!.layoutName);
                } else {
                  CustomSnackbars.showErrorSnackbar(
                    context,
                    'Layout name cannot be empty',
         
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Controls Guide'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoItem(
                  Icons.add_circle_outline,
                  'Width +',
                  'Expand the grid horizontally (add columns)',
                  '',
                  false,
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                _buildInfoItem(
                  Icons.remove_circle_outline,
                  'Width -',
                  'Shrink the grid horizontally (remove columns)',
                  '• Only appear when no seats are on the rightmost edge',
                  true,
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                _buildInfoItem(
                  Icons.add_circle,
                  'Height +',
                  'Expand the grid vertically (add rows)',
                  '',
                  false,
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                _buildInfoItem(
                  Icons.remove_circle,
                  'Height -',
                  'Shrink the grid vertically (remove rows)',
                  '• Only appear when no seats are on the bottom edge',
                  true,
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                _buildInfoItem(
                  Icons.delete_outlined,
                  'Clear All',
                  'Remove all seats from the grid',
                  '• Only appear when seats are present',
                  true,
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                _buildInfoItem(
                  Icons.save,
                  'Save',
                  'Save the current layout and create the event',
                  '',
                  false,
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                const Divider(),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                Text(
                  'Grid Interactions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                const Text('• Tap empty space: Add a seat'),
                const Text(
                  '• Tap seat: Change seat state (empty → booked → reserved)',
                ),
                const Text('• Long press seat: Delete the seat'),
                const Text('• Pinch & zoom: Scale the view'),
                const Text('• Drag: Pan around the grid'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it!',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String title,
    String description,
    String boldInfo,
    bool info,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.foregroundColor,
                ),
              ),
              const SizedBox(height: 2),
              info
                  ? Text(
                      boldInfo,
                      style: TextStyle(
                        fontSize: AppSizes.bodyFontSize(context) * 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Seating Designer',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context),
            color: AppColors.foregroundColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
      ),
      body: Column(
        children: [
          // stage in center to show direction
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.appBarColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'STAGE',
              style: TextStyle(
                color: AppColors.foregroundColor,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.bodyFontSize(context),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 3.0,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.foregroundColor,
                      width: 0.5,
                    ),
                    color: AppColors.backgroundColor,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.seatingLayout!.gridWidth,
                      childAspectRatio: 1,
                    ),
                    itemCount:
                        widget.seatingLayout!.gridWidth *
                        widget.seatingLayout!.gridHeight,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final x = index % widget.seatingLayout!.gridWidth;
                      final y = index ~/ widget.seatingLayout!.gridWidth;
                      final seat = widget.seatingLayout!.getSeatAt(x, y);

                      return GestureDetector(
                        onTap: () {
                          if (seat == null) {
                            final newSeat = Seat(
                              seatNumber: widget.seatingLayout!.totalSeats,
                              gridX: x,
                              gridY: y,
                            );
                            setState(() {
                              widget.seatingLayout!.addSeat(newSeat);
                              widget.seatingLayout!.reIndexSeats();
                            });
                          } else {
                            setState(() {
                              seat.state =
                                  SeatState.values[(seat.state.index + 1) %
                                      SeatState.values.length];
                            });
                          }
                        },
                        onLongPress: seat != null
                            ? () => _showDeleteSeatDialog(seat.seatNumber)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: seat != null
                                ? _getSeatColor(seat.state)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gridLineColor,
                              width: 0.7,
                            ),
                          ),
                          child: seat != null
                              ? Center(
                                  child: Text(
                                    '${seat.seatNumber + 1}',
                                    style: TextStyle(
                                      color: AppColors.foregroundColor,
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
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(AppSizes.containerPadding(context)),
        decoration: BoxDecoration(
          color: AppColors.shadeColor,
          borderRadius: BorderRadius.circular(
            AppSizes.getScreenWidth(context) * 0.03,
          ),
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent, // Make background transparent
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.primary,
            selectedFontSize: AppSizes.bodyFontSize(context) * 0.8,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                label: 'Info',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: widget.seatingLayout!.gridWidth < _maxGridDimension
                      ? AppColors.primary
                      : AppColors.shadeColor,
                ),
                label: 'Width +',
              ),
              if (_canShrinkGridHorizontally())
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.primary,
                  ),
                  label: 'Width -',
                ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.add_circle,
                  color: widget.seatingLayout!.gridHeight < _maxGridDimension
                      ? AppColors.primary
                      : AppColors.shadeColor,
                ),
                label: 'Height +',
              ),
              if (_canShrinkGridVertically())
                BottomNavigationBarItem(
                  icon: Icon(Icons.remove_circle, color: AppColors.primary),
                  label: 'Height -',
                ),
              if (widget.seatingLayout!.seatList.isNotEmpty)
                BottomNavigationBarItem(
                  icon: Icon(Icons.delete_outlined, color: AppColors.primary),
                  label: 'Clear',
                ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.save),
                label: 'Save',
              ),
            ],
            onTap: (index) {
              // Calculate the actual button based on dynamic visibility
              int buttonIndex = 0;
              // Info (always present)
              if (index == buttonIndex) {
                _showInfoDialog();
                return;
              }
              buttonIndex++;
              // Width + (always present)
              if (index == buttonIndex) {
                if (widget.seatingLayout!.gridWidth < _maxGridDimension) {
                  _expandGridHorizontally();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum grid width reached ($_maxGridDimension)',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
                return;
              }
              buttonIndex++;

              // Width - (conditional)
              if (_canShrinkGridHorizontally()) {
                if (index == buttonIndex) {
                  _shrinkGridHorizontally();
                  return;
                }
                buttonIndex++;
              }

              // Height + (always present)
              if (index == buttonIndex) {
                if (widget.seatingLayout!.gridHeight < _maxGridDimension) {
                  _expandGridVertically();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum grid height reached ($_maxGridDimension)',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
                return;
              }
              buttonIndex++;

              // Height - (conditional)
              if (_canShrinkGridVertically()) {
                if (index == buttonIndex) {
                  _shrinkGridVertically();
                  return;
                }
                buttonIndex++;
              }

              // Clear All (always present)
              if (index == buttonIndex) {
                _showClearAllDialog();
                return;
              }
              buttonIndex++;

              // Save (always present)
              if (index == buttonIndex) {
                _showLayoutNameDialog().then((layoutName) {});
                return;
              }
            },
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;
  final int gridWidth;
  final int gridHeight;

  GridPainter({
    required this.gridSize,
    required this.gridWidth,
    required this.gridHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 0.5;

    final width = gridWidth * gridSize;
    final height = gridHeight * gridSize;

    for (int i = 0; i <= gridHeight; i++) {
      canvas.drawLine(
        Offset(0, i * gridSize),
        Offset(width, i * gridSize),
        paint,
      );
    }
    for (int i = 0; i <= gridWidth; i++) {
      canvas.drawLine(
        Offset(i * gridSize, 0),
        Offset(i * gridSize, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridWidth != gridWidth ||
        oldDelegate.gridHeight != gridHeight ||
        oldDelegate.gridSize != gridSize;
  }
}
