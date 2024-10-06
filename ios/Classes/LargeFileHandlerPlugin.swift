import Flutter
import UIKit

public class LargeFileHandlerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "large_file_handler", binaryMessenger: registrar.messenger())
    let instance = LargeFileHandlerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "copyAssetToLocal":
      handleCopyAsset(call: call, result: result)

    case "copyUrlToLocal":
      handleCopyUrl(call: call, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleCopyAsset(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = extractArguments(call: call, requiredKeys: ["assetName", "targetPath"]),
          let assetName = args["assetName"] as? String,
          let targetPath = args["targetPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
      return
    }

    do {
      try copyAsset(assetName: assetName, targetPath: targetPath)
      result(nil)
    } catch {
      result(FlutterError(code: "ERROR", message: "Failed to copy asset", details: error.localizedDescription))
    }
  }

  private func handleCopyUrl(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = extractArguments(call: call, requiredKeys: ["url", "targetPath"]),
          let url = args["url"] as? String,
          let targetPath = args["targetPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
      return
    }

    downloadFile(from: url, targetPath: targetPath) { downloadResult in
      switch downloadResult {
      case .success:
        result(nil)
      case .failure(let error):
        result(FlutterError(code: "DOWNLOAD_ERROR", message: "Failed to download file", details: error.localizedDescription))
      }
    }
  }

  private func extractArguments(call: FlutterMethodCall, requiredKeys: [String]) -> [String: Any]? {
    guard let args = call.arguments as? [String: Any] else { return nil }
    for key in requiredKeys {
      if args[key] == nil { return nil }
    }
    return args
  }

  private func copyAsset(assetName: String, targetPath: String) throws {
    let flutterAssetPath = FlutterDartProject.lookupKey(forAsset: assetName)
    guard let bundleAssetPath = Bundle.main.path(forResource: flutterAssetPath, ofType: nil) else {
      throw NSError(domain: "Asset not found", code: 404, userInfo: nil)
    }

    try copyFile(from: bundleAssetPath, to: targetPath)
  }

  private func copyFile(from sourcePath: String, to targetPath: String) throws {
    let fileManager = FileManager.default
    let targetURL = URL(fileURLWithPath: targetPath)

    if fileManager.fileExists(atPath: targetURL.path) {
      try fileManager.removeItem(at: targetURL)
    }

    try fileManager.copyItem(at: URL(fileURLWithPath: sourcePath), to: targetURL)
  }

  private func downloadFile(from url: String, targetPath: String, completion: @escaping (Result<String, Error>) -> Void) {
    guard let downloadUrl = URL(string: url) else {
      completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
      return
    }

    let task = URLSession.shared.dataTask(with: downloadUrl) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }

      do {
        try self.saveData(data, to: targetPath)
        completion(.success(targetPath))
      } catch {
        completion(.failure(error))
      }
    }

    task.resume()
  }

  private func saveData(_ data: Data, to path: String) throws {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: path) {
      try fileManager.removeItem(atPath: path)
    }

    fileManager.createFile(atPath: path, contents: nil, attributes: nil)

    let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
    fileHandle.write(data)
    fileHandle.closeFile()
  }
}
