import 'dart:async';
import 'large_file_handler_platform_interface.dart';

class LargeFileHandler {
  Future<void> copyAssetToLocalStorage({required String assetName, required String targetPath}) =>
      LargeFileHandlerPlatform.instance.copyAssetToLocalStorage(assetName, targetPath);

  Future<void> copyUrlToLocalStorage({required String assetUrl, required String targetPath}) =>
      LargeFileHandlerPlatform.instance.copyUrlToLocalStorage(assetUrl, targetPath);
}
