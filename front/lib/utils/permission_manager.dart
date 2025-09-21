import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  /// Singleton instance
  static final PermissionManager _instance = PermissionManager._internal();
  
  factory PermissionManager() => _instance;
  
  PermissionManager._internal();
  
  /// Request all app permissions at once (usually called during splash screen)
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.camera,      // For taking photos and videos
      Permission.microphone,  // For voice messages and calls
      Permission.storage,     // For accessing media and files
      Permission.photos,      // For iOS photo library access
      // Add other permissions as needed
    ];
    
    // Request all permissions at once
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses;
  }
  
  /// Check if specific permission is granted
  Future<bool> hasPermission(Permission permission) async {
    return await permission.isGranted;
  }
  
  /// Show permission dialog with explanation
  Future<void> showPermissionRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('SETTINGS'),
          ),
        ],
      ),
    );
  }
}
