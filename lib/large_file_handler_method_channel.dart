import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'large_file_handler_platform_interface.dart';

/// An implementation of [LargeFileHandlerPlatform] that uses method channels.
class MethodChannelLargeFileHandler extends LargeFileHandlerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('large_file_handler');

  @override
  Future<void> copyAssetToLocalStorage(String assetName, String targetName) async {
    final String targetPath = await _getLocalFilePath(targetName);
    await methodChannel.invokeMethod('copyAssetToLocal', {
      'assetName': 'assets/$assetName',
      'targetPath': targetPath,
    });
  }

  @override
  Future<void> copyUrlToLocalStorage(String url, String targetName) async {
    final String targetPath = await _getLocalFilePath(targetName);
    await methodChannel.invokeMethod('copyUrlToLocal', {
      'url': url,
      'targetPath': targetPath,
    });
  }

  Future<String> _getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
