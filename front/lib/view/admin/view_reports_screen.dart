import 'package:flutter/material.dart';
import 'package:front/controller/report_controller.dart';
import 'package:front/controller/unban_request_controller.dart';
import 'package:front/model/report_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/time_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Report> _allReports = [];
  List<Report> _userReports = [];
  List<Report> _listItemReports = [];
  List<Report> _reactivationRequests = [];
  List<Report> _unbanRequests = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    final reports = await ReportController.getAllReports(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );
    
    final unbanReqs = await UnbanRequestController.getAllUnbanRequests(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );

    setState(() {
      _allReports = [...reports, ...unbanReqs];
      _userReports = reports.where((r) => r.reportType == 'user').toList();
      _listItemReports = reports
          .where((r) => r.reportType == 'listitem')
          .toList();
      _reactivationRequests = reports
          .where((r) => r.reportType == 'reactivation_request')
          .toList();
      _unbanRequests = unbanReqs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Reports',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        backgroundColor: AppColors.appBarColor,
        iconTheme: IconThemeData(color: AppColors.foregroundColor),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: AppColors.foregroundColor),
            onSelected: (value) {
              setState(() => _selectedStatus = value);
              _loadReports();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.foregroundColor,
          unselectedLabelColor: AppColors.foregroundColor.withOpacity(0.6),
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${_allReports.length})'),
            Tab(text: 'Users (${_userReports.length})'),
            Tab(text: 'Listings (${_listItemReports.length})'),
            Tab(text: 'Reactivations (${_reactivationRequests.length})'),
            Tab(text: 'Unban (${_unbanRequests.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsList(_allReports),
                _buildReportsList(_userReports),
                _buildReportsList(_listItemReports),
                _buildReportsList(_reactivationRequests),
                _buildUnbanRequestsList(_unbanRequests),
              ],
            ),
    );
  }

  Widget _buildReportsList(List<Report> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.shadeColor.withOpacity(0.5),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            Text(
              'No reports found',
              style: TextStyle(
                fontSize: AppSizes.titleFontSize(context),
                color: AppColors.shadeColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: EdgeInsets.all(AppSizes.smallPadding(context)),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    final isUserReport = report.reportType == 'user';

    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.smallSpacing(context)),
      elevation: AppSizes.cardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUserReport
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUserReport ? 'USER' : 'LISTING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUserReport ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(report.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    TimeUtils.formatDatePKT(report.createdAt),
                    style: TextStyle(
                      fontSize: AppSizes.subtitleFontSize(context) * 0.85,
                      color: AppColors.shadeColor,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSizes.mediumSpacing(context)),

              // Reported entity info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage:
                        isUserReport && report.reportedUserImageUrl != null
                        ? CachedNetworkImageProvider(
                            report.reportedUserImageUrl!,
                          )
                        : null,
                    child:
                        (isUserReport && report.reportedUserImageUrl == null) ||
                            !isUserReport
                        ? Icon(
                            isUserReport ? Icons.person : Icons.shopping_bag,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  SizedBox(width: AppSizes.mediumSpacing(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUserReport
                              ? report.reportedUserName ?? 'Unknown User'
                              : report.reportedListItemTitle ??
                                    'Unknown Listing',
                          style: TextStyle(
                            fontSize: AppSizes.titleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Reported by: ${report.reportedByName}',
                          style: TextStyle(
                            fontSize: AppSizes.subtitleFontSize(context) * 0.9,
                            color: AppColors.shadeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSizes.smallSpacing(context)),

              // Reason
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.shadeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.reason,
                  style: TextStyle(
                    fontSize: AppSizes.subtitleFontSize(context),
                    color: AppColors.titleColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (report.actionTaken != 'none') ...[
                SizedBox(height: AppSizes.smallSpacing(context)),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Action: ${report.actionTaken.replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(
                        fontSize: AppSizes.subtitleFontSize(context) * 0.85,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'ignored':
        return Colors.grey;
      default:
        return AppColors.shadeColor;
    }
  }

  void _showReportDetails(Report report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportDetailsSheet(report),
    );
  }

  Widget _buildReportDetailsSheet(Report report) {
    final isUserReport = report.reportType == 'user';
    final isReactivationRequest = report.reportType == 'reactivation_request';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.shadeColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
            child: Row(
              children: [
                Text(
                  'Report Details',
                  style: TextStyle(
                    fontSize: AppSizes.titleFontSize(context) * 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.foregroundColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Report Type:',
                    isReactivationRequest
                        ? 'Reactivation Request'
                        : isUserReport
                        ? 'User Report'
                        : 'Listing Report',
                  ),
                  _buildDetailRow('Status:', report.status.toUpperCase()),
                  _buildDetailRow('Reported By:', report.reportedByName ?? 'N/A'),
                  _buildDetailRow(
                    'Report Date:',
                    TimeUtils.formatDateTimePKT(report.createdAt),
                  ),

                  if (isUserReport) ...[
                    _buildDetailRow(
                      'Reported User:',
                      report.reportedUserName ?? 'Unknown',
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailRow(
                            'Reported Listing:',
                            report.reportedListItemTitle ?? 'Unknown',
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showListingDetails(report),
                          icon: Icon(Icons.info_outline, size: 16),
                          label: Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.foregroundColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: AppSizes.mediumSpacing(context)),

                  Text(
                    isReactivationRequest ? 'Reactivation Reason:' : 'Reason:',
                    style: TextStyle(
                      fontSize: AppSizes.titleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: AppColors.titleColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.shadeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.reason,
                      style: TextStyle(
                        fontSize: AppSizes.subtitleFontSize(context),
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),

                  if (report.adminNotes != null &&
                      report.adminNotes!.isNotEmpty) ...[
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    Text(
                      'Admin Notes:',
                      style: TextStyle(
                        fontSize: AppSizes.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.adminNotes!,
                        style: TextStyle(
                          fontSize: AppSizes.subtitleFontSize(context),
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                  ],

                  if (report.actionTaken != 'none') ...[
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    _buildDetailRow(
                      'Action Taken:',
                      report.actionTaken.replaceAll('_', ' ').toUpperCase(),
                    ),
                    if (report.reviewedByName != null)
                      _buildDetailRow('Reviewed By:', report.reviewedByName!),
                    if (report.reviewedAt != null)
                      _buildDetailRow(
                        'Reviewed At:',
                        TimeUtils.formatDateTimePKT(report.reviewedAt!),
                      ),
                  ],

                  // Action buttons
                  if (report.status == 'pending' ||
                      report.status == 'reviewed') ...[
                    SizedBox(height: AppSizes.largeSpacing(context)),
                    Text(
                      'Take Action:',
                      style: TextStyle(
                        fontSize: AppSizes.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),

                    if (isUserReport) ...[
                      _buildActionButton(
                        'Ban User',
                        Icons.block,
                        Colors.red,
                        () => _handleUserAction(report, 'ban'),
                      ),
                      SizedBox(height: 8),
                      _buildActionButton(
                        'Delete User',
                        Icons.delete_forever,
                        Colors.red[900]!,
                        () => _handleUserAction(report, 'delete'),
                      ),
                      SizedBox(height: 8),
                      _buildActionButton(
                        'Ignore Report',
                        Icons.cancel,
                        Colors.grey,
                        () => _handleUserAction(report, 'ignore'),
                      ),
                    ] else if (isReactivationRequest) ...[
                      _buildActionButton(
                        'Approve Reactivation',
                        Icons.check_circle,
                        Colors.green,
                        () => _handleReactivationAction(report, 'accept'),
                      ),
                      SizedBox(height: 8),
                      _buildActionButton(
                        'Reject Request',
                        Icons.cancel,
                        Colors.red,
                        () => _handleReactivationAction(report, 'reject'),
                      ),
                    ] else ...[
                      _buildActionButton(
                        'Remove Listing',
                        Icons.delete,
                        Colors.red,
                        () => _handleListItemAction(report, 'remove'),
                      ),
                      SizedBox(height: 8),
                      _buildActionButton(
                        'Ignore Report',
                        Icons.cancel,
                        Colors.grey,
                        () => _handleListItemAction(report, 'ignore'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.w600,
                color: AppColors.shadeColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                color: AppColors.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserAction(Report report, String action) async {
    final TextEditingController notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to ${action} this user?'),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context); // Close details sheet

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await ReportController.handleUserReport(
        reportId: report.id,
        action: action,
        adminNotes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result.contains('success')) {
          CustomSnackbars.showSuccessSnackbar(context, result, 2);
          _loadReports();
        } else {
          CustomSnackbars.showErrorSnackbar(context, result);
        }
      }
    }

    notesController.dispose();
  }

  Future<void> _handleListItemAction(Report report, String action) async {
    final TextEditingController notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to ${action} this listing?'),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: action == 'remove'
                    ? 'Reason for removal*'
                    : 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
                helperText: action == 'remove'
                    ? 'This will be sent to the listing owner'
                    : null,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (action == 'remove' && notesController.text.trim().isEmpty) {
                CustomSnackbars.showErrorSnackbar(
                  context,
                  'Please provide a reason for removal',
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context); // Close details sheet

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await ReportController.handleListItemReport(
        reportId: report.id,
        action: action,
        adminNotes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result.contains('success')) {
          CustomSnackbars.showSuccessSnackbar(context, result, 2);
          _loadReports();
        } else {
          CustomSnackbars.showErrorSnackbar(context, result);
        }
      }
    }

    notesController.dispose();
  }

  Future<void> _handleReactivationAction(Report report, String action) async {
    final TextEditingController notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          'Confirm Action',
          style: TextStyle(color: AppColors.titleColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action == 'accept'
                  ? 'Are you sure you want to approve this reactivation request and make the listing active again?'
                  : 'Are you sure you want to reject this reactivation request?',
              style: TextStyle(color: AppColors.foregroundColor),
            ),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: TextStyle(color: AppColors.foregroundColor),
              decoration: InputDecoration(
                labelText: action == 'reject'
                    ? 'Reason for rejection*'
                    : 'Admin Notes (Optional)',
                labelStyle: TextStyle(color: AppColors.shadeColor),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.shadeColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                helperText: action == 'reject'
                    ? 'This will be sent to the listing owner'
                    : null,
                helperStyle: TextStyle(color: AppColors.shadeColor),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.shadeColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (action == 'reject' && notesController.text.trim().isEmpty) {
                CustomSnackbars.showErrorSnackbar(
                  context,
                  'Please provide a reason for rejection',
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept' ? Colors.green : Colors.red,
              foregroundColor: AppColors.foregroundColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context); // Close details sheet

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );

      final result = await ReportController.handleReactivationRequest(
        reportId: report.id,
        action: action,
        adminNotes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result.contains('success')) {
          CustomSnackbars.showSuccessSnackbar(context, result, 2);
          _loadReports();
        } else {
          CustomSnackbars.showErrorSnackbar(context, result);
        }
      }
    }

    notesController.dispose();
  }

  void _showListingDetails(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          children: [
            Icon(Icons.shopping_bag, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Listing Details',
                style: TextStyle(color: AppColors.titleColor),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              if (report.reportedListItemImages != null &&
                  report.reportedListItemImages!.isNotEmpty)
                Container(
                  height: 200,
                  child: PageView.builder(
                    itemCount: report.reportedListItemImages!.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          report.reportedListItemImages![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.shadeColor.withOpacity(0.2),
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: AppColors.shadeColor,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

              SizedBox(height: 16),

              // Title
              Text(
                report.reportedListItemTitle ?? 'Unknown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),

              SizedBox(height: 8),

              // Price
              if (report.reportedListItemPrice != null)
                Text(
                  '\$${report.reportedListItemPrice!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

              SizedBox(height: 16),

              // Category, Brand, Condition
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (report.reportedListItemCategory != null)
                    _buildInfoChip(
                      'Category',
                      report.reportedListItemCategory!,
                    ),
                  if (report.reportedListItemBrand != null)
                    _buildInfoChip('Brand', report.reportedListItemBrand!),
                  if (report.reportedListItemCondition != null)
                    _buildInfoChip(
                      'Condition',
                      report.reportedListItemCondition!,
                    ),
                ],
              ),

              SizedBox(height: 16),

              // Description
              if (report.reportedListItemDescription != null &&
                  report.reportedListItemDescription!.isNotEmpty) ...[
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleColor,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.shadeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.reportedListItemDescription!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.foregroundColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.foregroundColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.shadeColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnbanRequestsList(List<Report> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.shadeColor.withOpacity(0.5),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            Text(
              'No unban requests found',
              style: TextStyle(
                fontSize: AppSizes.titleFontSize(context),
                color: AppColors.shadeColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: EdgeInsets.all(AppSizes.mediumSpacing(context)),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            color: AppColors.surfaceColor,
            margin: EdgeInsets.only(bottom: AppSizes.mediumSpacing(context)),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showUnbanRequestDetails(request),
              child: Padding(
                padding: EdgeInsets.all(AppSizes.mediumSpacing(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(request.status),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          TimeUtils.formatDatePKT(request.createdAt),
                          style: TextStyle(
                            fontSize: AppSizes.subtitleFontSize(context) * 0.85,
                            color: AppColors.shadeColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: request.reportedUserImageUrl != null
                              ? CachedNetworkImageProvider(request.reportedUserImageUrl!)
                              : null,
                          child: request.reportedUserImageUrl == null
                              ? Icon(Icons.person, color: AppColors.primary)
                              : null,
                        ),
                        SizedBox(width: AppSizes.mediumSpacing(context)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.reportedUserName ?? 'Unknown User',
                                style: TextStyle(
                                  fontSize: AppSizes.titleFontSize(context),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.foregroundColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                request.reason.length > 100
                                    ? '${request.reason.substring(0, 100)}...'
                                    : request.reason,
                                style: TextStyle(
                                  fontSize: AppSizes.subtitleFontSize(context),
                                  color: AppColors.shadeColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.shadeColor,
                        ),
                      ],
                    ),
                    if (request.proofImages.isNotEmpty) ...[
                      SizedBox(height: AppSizes.smallSpacing(context)),
                      Row(
                        children: [
                          Icon(Icons.image, size: 16, color: AppColors.shadeColor),
                          SizedBox(width: 4),
                          Text(
                            '${request.proofImages.length} proof image(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.shadeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUnbanRequestDetails(Report request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.mediumSpacing(context) * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_open, color: AppColors.primary, size: 28),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unban Request Details',
                        style: TextStyle(
                          fontSize: AppSizes.titleFontSize(context) * 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.mediumSpacing(context)),
                Container(
                  padding: EdgeInsets.all(AppSizes.mediumSpacing(context)),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            backgroundImage: request.reportedUserImageUrl != null
                                ? CachedNetworkImageProvider(request.reportedUserImageUrl!)
                                : null,
                            child: request.reportedUserImageUrl == null
                                ? Icon(Icons.person, size: 30, color: AppColors.primary)
                                : null,
                          ),
                          SizedBox(width: AppSizes.mediumSpacing(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.reportedUserName ?? 'Unknown User',
                                  style: TextStyle(
                                    fontSize: AppSizes.titleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.foregroundColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(request.status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    request.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(request.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.mediumSpacing(context)),
                      Divider(color: AppColors.shadeColor.withOpacity(0.3)),
                      SizedBox(height: AppSizes.mediumSpacing(context)),
                      Text(
                        'User\'s Message:',
                        style: TextStyle(
                          fontSize: AppSizes.subtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: AppColors.shadeColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        request.reason,
                        style: TextStyle(
                          fontSize: AppSizes.subtitleFontSize(context),
                          color: AppColors.foregroundColor,
                        ),
                      ),
                      if (request.proofImages.isNotEmpty) ...[
                        SizedBox(height: AppSizes.mediumSpacing(context)),
                        Text(
                          'Proof Images:',
                          style: TextStyle(
                            fontSize: AppSizes.subtitleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: AppColors.shadeColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: request.proofImages.map((imageUrl) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 100,
                                  height: 100,
                                  color: AppColors.shadeColor.withOpacity(0.2),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
                        SizedBox(height: AppSizes.mediumSpacing(context)),
                        Divider(color: AppColors.shadeColor.withOpacity(0.3)),
                        SizedBox(height: AppSizes.mediumSpacing(context)),
                        Text(
                          'Admin Notes:',
                          style: TextStyle(
                            fontSize: AppSizes.subtitleFontSize(context),
                            fontWeight: FontWeight.bold,
                            color: AppColors.shadeColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.shadeColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            request.adminNotes!,
                            style: TextStyle(
                              fontSize: AppSizes.subtitleFontSize(context),
                              color: AppColors.foregroundColor,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: AppSizes.mediumSpacing(context)),
                      Text(
                        'Submitted: ${TimeUtils.formatToPKT(request.createdAt, 'MMM dd, yyyy - hh:mm a')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.shadeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (request.status == 'pending') ...[
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleUnbanRequest(request, 'rejected');
                          },
                          icon: Icon(Icons.close),
                          label: Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleUnbanRequest(request, 'approved');
                          },
                          icon: Icon(Icons.check),
                          label: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: AppColors.foregroundColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUnbanRequest(Report request, String status) async {
    final TextEditingController notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          status == 'approved' ? 'Approve Unban Request' : 'Reject Unban Request',
          style: TextStyle(color: AppColors.titleColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add notes for this decision:',
              style: TextStyle(color: AppColors.foregroundColor),
            ),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              style: TextStyle(color: AppColors.foregroundColor),
              decoration: InputDecoration(
                hintText: 'Admin notes (optional)',
                hintStyle: TextStyle(color: AppColors.shadeColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.shadeColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final result = await UnbanRequestController.reviewUnbanRequest(
        requestId: request.id,
        status: status,
        adminNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      );

      Navigator.pop(context);

      if (result.contains('success') || result.contains(status)) {
        CustomSnackbars.showSuccessSnackbar(context, result, 2);
        _loadReports();
      } else {
        CustomSnackbars.showErrorSnackbar(context, result);
      }
    }
  }
}
