import Flutter
import UIKit

public class SwiftLargeFileHandlerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "large_file_handler", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "file_download_progress", binaryMessenger: registrar.messenger())
    let instance = SwiftLargeFileHandlerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "copyAssetToLocal":
      guard let args = call.arguments as? [String: Any],
      let assetName = args["assetName"] as? String,
      let targetPath = args["targetPath"] as? String else {
      result(FlutterError(code: "ERROR", message: "Invalid arguments", details: nil))
      return
    }
      copyAssetToLocal(assetName: assetName, targetPath: targetPath, result: result)

      case "copyAssetToLocalWithProgress":
      guard let args = call.arguments as? [String: Any],
      let assetName = args["assetName"] as? String,
      let targetPath = args["targetPath"] as? String else {
      result(FlutterError(code: "ERROR", message: "Invalid arguments", details: nil))
      return
    }
      DispatchQueue.global().async {
        self.copyAssetToLocalWithProgress(assetName: assetName, targetPath: targetPath, result: result)
      }

      case "copyUrlToLocal":
      guard let args = call.arguments as? [String: Any],
      let url = args["url"] as? String,
      let targetPath = args["targetPath"] as? String else {
      result(FlutterError(code: "ERROR", message: "Invalid arguments", details: nil))
      return
    }
      DispatchQueue.global().async {
        self.downloadFileFromUrl(url: url, targetPath: targetPath, result: result)
      }

      case "copyUrlToLocalWithProgress":
      guard let args = call.arguments as? [String: Any],
      let url = args["url"] as? String,
      let targetPath = args["targetPath"] as? String else {
      result(FlutterError(code: "ERROR", message: "Invalid arguments", details: nil))
      return
    }
      DispatchQueue.global().async {
        self.downloadFileFromUrlWithProgress(url: url, targetPath: targetPath, result: result)
      }

      default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func copyAssetToLocal(assetName: String, targetPath: String, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      do {
        if let asset = NSDataAsset(name: assetName) {
          let data = asset.data
                  let fileURL = URL(fileURLWithPath: targetPath)
          try data.write(to: fileURL)
            result(nil)
          } else {
          result(FlutterError(code: "ERROR", message: "Failed to load asset", details: nil))
        }
      } catch {
        result(FlutterError(code: "ERROR", message: "Failed to copy asset", details: error.localizedDescription))
      }
    }
  }

  private func copyAssetToLocalWithProgress(assetName: String, targetPath: String, result: @escaping FlutterResult) {
    do {
      if let asset = NSDataAsset(name: assetName) {
        let data = asset.data
                let fileURL = URL(fileURLWithPath: targetPath)
        let totalBytes = Int64(data.count)
        var bytesWritten: Int64 = 0
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let inputStream = InputStream(data: data)
        let outputStream = OutputStream(url: fileURL, append: false)
        inputStream.open()
        outputStream?.open()
        defer {
          inputStream.close()
          outputStream?.close()
          buffer.deallocate()
        }

        while inputStream.hasBytesAvailable {
          let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
          if bytesRead <= 0 { break }
          outputStream?.write(buffer, maxLength: bytesRead)
          bytesWritten += Int64(bytesRead)
          let progress = (Double(bytesWritten) / Double(totalBytes)) * 100
          DispatchQueue.main.async {
            self.eventSink?(Int(progress))
          }
        }
        DispatchQueue.main.async {
          self.eventSink?(100)
          result(nil)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "ERROR", message: "Failed to load asset", details: nil))
        }
      }
    } catch {
      DispatchQueue.main.async {
        result(FlutterError(code: "ERROR", message: "Failed to copy asset", details: error.localizedDescription))
      }
    }
  }

  private func downloadFileFromUrl(url: String, targetPath: String, result: @escaping FlutterResult) {
    guard let fileUrl = URL(string: url) else {
      DispatchQueue.main.async {
        result(FlutterError(code: "DOWNLOAD_FAILED", message: "Invalid URL", details: nil))
      }
      return
    }
    do {
      let data = try Data(contentsOf: fileUrl)
        let fileURL = URL(fileURLWithPath: targetPath)
        try data.write(to: fileURL)
          DispatchQueue.main.async {
            result(nil)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "DOWNLOAD_FAILED", message: "Error during file download: \(error.localizedDescription)", details: nil))
          }
        }
      }

  private func downloadFileFromUrlWithProgress(url: String, targetPath: String, result: @escaping FlutterResult) {
    guard let fileUrl = URL(string: url) else {
      DispatchQueue.main.async {
        result(FlutterError(code: "DOWNLOAD_FAILED", message: "Invalid URL", details: nil))
      }
      return
    }

    let task = URLSession.shared.downloadTask(with: fileUrl) { (tempURL, response, error) in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(code: "DOWNLOAD_FAILED", message: "Error during file download: \(error.localizedDescription)", details: nil))
        }
        return
      }

      guard let tempURL = tempURL, let response = response else {
        DispatchQueue.main.async {
          result(FlutterError(code: "DOWNLOAD_FAILED", message: "Unknown error", details: nil))
        }
        return
      }

      let totalBytes = response.expectedContentLength
      var bytesWritten: Int64 = 0

      do {
        let fileURL = URL(fileURLWithPath: targetPath)
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
          bytesWritten = totalBytes
          DispatchQueue.main.async {
            self.eventSink?(100)
            result(nil)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "DOWNLOAD_FAILED", message: "Error during file download: \(error.localizedDescription)", details: nil))
          }
        }
      }

    task.resume()

    task.progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: [.new], context: nil)
  }

  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == #keyPath(Progress.fractionCompleted), let progress = object as? Progress {
      DispatchQueue.main.async {
        let percentage = Int(progress.fractionCompleted * 100)
        self.eventSink?(percentage)
      }
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
