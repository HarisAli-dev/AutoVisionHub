import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  /// Singleton instance
  static final PermissionManager _instance = PermissionManager._internal();

  factory PermissionManager() => _instance;

  PermissionManager._internal();

  /// Request all app permissions at once (usually called during splash screen)
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = <Permission>[
      Permission.camera, // For taking photos and videos
      Permission.microphone, // For voice messages and calls
      if (!kIsWeb)
        Permission
            .storage, // For accessing media and files (unsupported on web)
      if (!kIsWeb) Permission.photos, // For iOS photo library access
    ];

    // Request all permissions at once
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Check for permanently denied permissions and handle them
    for (var entry in statuses.entries) {
      if (entry.value.isPermanentlyDenied) {
        debugPrint('⚠️ Permission ${entry.key} is permanently denied');
      } else if (entry.value.isDenied) {
        debugPrint('⚠️ Permission ${entry.key} is denied');
        // Request again for denied permissions
        await entry.key.request();
      }
    }

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
