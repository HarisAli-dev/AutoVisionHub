import 'package:flutter/material.dart';
import 'package:front/controller/groups/thread_controller.dart';
import 'package:front/model/groups/thread_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/community_member/threads/thread_screen.dart';
import 'package:front/view/community_member/threads/create_thread_screen.dart';
import 'package:front/utils/time_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ThreadsListScreen extends StatefulWidget {
  const ThreadsListScreen({super.key});

  @override
  State<ThreadsListScreen> createState() => _ThreadsListScreenState();
}

class _ThreadsListScreenState extends State<ThreadsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Thread> _allThreads = [];
  List<Thread> _myThreads = [];
  bool _isLoading = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = HiveUtils.getData('userId') ?? '';
    _loadThreads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    setState(() => _isLoading = true);
    final allThreads = await ThreadController.getAllThreads();
    final myThreads = await ThreadController.getUserThreads();
    setState(() {
      _allThreads = allThreads;
      _myThreads = myThreads;
      _isLoading = false;
    });
  }

  Future<void> _deleteThread(Thread thread) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discussion'),
        content: Text(
          'Are you sure you want to delete "${thread.topicName}"?\n\nThis action cannot be undone and will delete all messages in this discussion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await ThreadController.deleteThread(thread.id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result.contains('success')) {
          CustomSnackbars.showSuccessSnackbar(
            context,
            'Discussion deleted successfully',
            1,
          );
          _loadThreads();
        } else {
          CustomSnackbars.showErrorSnackbar(context, result);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.appBarColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.foregroundColor,
              unselectedLabelColor: AppColors.foregroundColor.withOpacity(0.6),
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'All Discussions'),
                Tab(text: 'My Discussions'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildThreadsList(_allThreads, isMyThreads: false),
                      _buildThreadsList(_myThreads, isMyThreads: true),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateThreadScreen()),
          );
          if (result == true) {
            _loadThreads();
          }
        },
        child: Icon(Icons.add, color: AppColors.foregroundColor),
      ),
    );
  }

  Widget _buildThreadsList(List<Thread> threads, {required bool isMyThreads}) {
    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: AppColors.shadeColor.withOpacity(0.5),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            Text(
              isMyThreads
                  ? 'No discussions yet\nJoin or create a discussion'
                  : 'No discussions available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.subtitleFontSize(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.builder(
        itemCount: threads.length,
        padding: EdgeInsets.all(AppSizes.smallPadding(context)),
        itemBuilder: (context, index) {
          final thread = threads[index];
          final isJoined = thread.participants.contains(_currentUserId);
          final isCreator = thread.createdBy == _currentUserId;

          return Card(
            margin: EdgeInsets.only(bottom: AppSizes.smallSpacing(context)),
            elevation: AppSizes.cardElevation(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppSizes.cardBorderRadius(context),
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              leading: thread.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: thread.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.primary.withOpacity(0.2),
                          child: Icon(Icons.forum, color: AppColors.primary),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.primary.withOpacity(0.2),
                          child: Icon(Icons.forum, color: AppColors.primary),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: thread.creatorImageUrl != null
                          ? CachedNetworkImageProvider(thread.creatorImageUrl!)
                          : null,
                      child: thread.creatorImageUrl == null
                          ? Icon(Icons.forum, color: AppColors.primary)
                          : null,
                    ),
              title: Text(
                thread.topicName,
                style: TextStyle(
                  fontSize: AppSizes.titleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thread.description != null) ...[
                    SizedBox(height: AppSizes.smallSpacing(context) / 2),
                    Text(
                      thread.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.shadeColor,
                        fontSize: AppSizes.subtitleFontSize(context),
                      ),
                    ),
                  ],
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: AppColors.shadeColor),
                      SizedBox(width: 4),
                      Text(
                        thread.creatorName,
                        style: TextStyle(
                          color: AppColors.shadeColor,
                          fontSize: AppSizes.subtitleFontSize(context) * 0.9,
                        ),
                      ),
                      SizedBox(width: AppSizes.mediumSpacing(context)),
                      Icon(
                        Icons.message,
                        size: 14,
                        color: AppColors.shadeColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${thread.messageCount}',
                        style: TextStyle(
                          color: AppColors.shadeColor,
                          fontSize: AppSizes.subtitleFontSize(context) * 0.9,
                        ),
                      ),
                      SizedBox(width: AppSizes.mediumSpacing(context)),
                      Icon(Icons.group, size: 14, color: AppColors.shadeColor),
                      SizedBox(width: 4),
                      Text(
                        '${thread.participants.length}',
                        style: TextStyle(
                          color: AppColors.shadeColor,
                          fontSize: AppSizes.subtitleFontSize(context) * 0.9,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context) / 2),
                  Text(
                    TimeUtils.formatDatePKT(thread.updatedAt),
                    style: TextStyle(
                      color: AppColors.shadeColor.withOpacity(0.7),
                      fontSize: AppSizes.subtitleFontSize(context) * 0.85,
                    ),
                  ),
                ],
              ),
              trailing: isJoined
                  ? Icon(Icons.check_circle, color: AppColors.primary)
                  : Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.shadeColor,
                    ),
              onLongPress: isCreator ? () => _deleteThread(thread) : null,
              onTap: () async {
                if (!isJoined && !isCreator) {
                  // Show join confirmation
                  final join = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Join Discussion'),
                      content: Text(
                        'Would you like to join "${thread.topicName}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Join'),
                        ),
                      ],
                    ),
                  );

                  if (join == true && mounted) {
                    final result = await ThreadController.joinThread(thread.id);
                    if (mounted) {
                      if (result.contains('success')) {
                        CustomSnackbars.showSuccessSnackbar(context, result, 1);
                        _loadThreads();
                      } else {
                        CustomSnackbars.showErrorSnackbar(context, result);
                      }
                    }
                  }
                } else {
                  // Open thread
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreadScreen(
                        threadId: thread.id,
                        topicName: thread.topicName,
                        currentUserId: _currentUserId,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadThreads();
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}
