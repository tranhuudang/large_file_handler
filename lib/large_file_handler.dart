import 'dart:async';
import 'large_file_handler_platform_interface.dart';

class LargeFileHandler {
  Future<void> copyAssetToLocalStorage({required String assetName, required String targetPath}) =>
      LargeFileHandlerPlatform.instance.copyAssetToLocalStorage(assetName, targetPath);

  Future<void> copyNetworkAssetToLocalStorage({required String assetUrl, required String targetPath}) =>
      LargeFileHandlerPlatform.instance.copyUrlToLocalStorage(assetUrl, targetPath);

  Stream<int> copyAssetToLocalStorageWithProgress(
          {required String assetName, required String targetPath}) =>
      LargeFileHandlerPlatform.instance.copyAssetToLocalStorageWithProgress(assetName, targetPath);

  Stream<int> copyNetworkAssetToLocalStorageWithProgress(
          {required String assetUrl, required String targetPath}) =>
      LargeFileHandlerPlatform.instance.copyUrlToLocalStorageWithProgress(assetUrl, targetPath);
}
