package com.example.large_file_handler

import android.content.res.AssetManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.loader.FlutterLoader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream

class LargeFileHandlerPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var assetManager: AssetManager
  private lateinit var flutterLoader: FlutterLoader

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "large_file_handler")
    channel.setMethodCallHandler(this)
    assetManager = flutterPluginBinding.applicationContext.assets

    flutterLoader = FlutterLoader()
    flutterLoader.startInitialization(flutterPluginBinding.applicationContext)
    flutterLoader.ensureInitializationComplete(flutterPluginBinding.applicationContext, null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "copyAssetToLocal" -> {
        val assetName = call.argument<String>("assetName")!!
        val targetPath = call.argument<String>("targetPath")!!
        try {
          val assetStream = assetManager.open(flutterLoader.getLookupKeyForAsset(assetName))
          copyStreamToFile(assetStream, targetPath)
          result.success(null)
        } catch (e: IOException) {
          result.error("ERROR", "Failed to copy asset", e)
        }
      }
      "copyUrlToLocal" -> {
        val url = call.argument<String>("url")!!
        val targetPath = call.argument<String>("targetPath")!!
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val inputStream = downloadFileFromUrl(url)
            copyStreamToFile(inputStream, targetPath)
            result.success(null)
          } catch (e: Exception) {
            result.error("DOWNLOAD_FAILED", "Error during file download: ${e.message}", null)
          }
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun downloadFileFromUrl(url: String): InputStream {
    val client = OkHttpClient()
    val request = Request.Builder().url(url).build()
    val response = client.newCall(request).execute()

    if (!response.isSuccessful) {
      throw IOException("Failed to download file: ${response.code}")
    }

    return response.body?.byteStream() ?: throw IOException("Response body is null")
  }

  private fun copyStreamToFile(inputStream: InputStream, targetPath: String) {
    inputStream.use { input ->
      FileOutputStream(File(targetPath)).use { output ->
        val buffer = ByteArray(1024)
        var length: Int
        while (input.read(buffer).also { length = it } > 0) {
          output.write(buffer, 0, length)
        }
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
