import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'large_file_handler_method_channel.dart';

abstract class LargeFileHandlerPlatform extends PlatformInterface {
  /// Constructs a LargeFileHandlerPlatform.
  LargeFileHandlerPlatform() : super(token: _token);

  static final Object _token = Object();

  static LargeFileHandlerPlatform _instance = MethodChannelLargeFileHandler();

  /// The default instance of [LargeFileHandlerPlatform] to use.
  ///
  /// Defaults to [MethodChannelLargeFileHandler].
  static LargeFileHandlerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LargeFileHandlerPlatform] when
  /// they register themselves.
  static set instance(LargeFileHandlerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> copyUrlToLocalStorage(String url, String targetName);

  Future<void> copyAssetToLocalStorage(String assetName, String targetName);

  Stream<int> copyAssetToLocalStorageWithProgress(String assetName, String targetName);

  Stream<int> copyUrlToLocalStorageWithProgress(String url, String targetName);
}
