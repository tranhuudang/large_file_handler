import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:large_file_handler/large_file_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _statusMessage = 'Copying asset...';
  StreamSubscription<int>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    copyAssetToLocalWithProgress();
  }

  Future<void> copyAssetToLocalWithProgress() async {
    try {
      const assetName = 'example.json';
      const targetPath = 'example.json';

      Stream<int> progressStream = LargeFileHandler().copyAssetToLocalStorageWithProgress(
        assetName: assetName,
        targetPath: targetPath,
      );

      _progressSubscription = progressStream.listen(
        (progress) {
          setState(() {
            _statusMessage = 'Copying asset... $progress%';
          });
        },
        onDone: () {
          setState(() {
            _statusMessage = 'File copied successfully to $targetPath';
          });
        },
        onError: (error) {
          setState(() {
            _statusMessage = 'Failed to copy asset: $error';
          });
        },
      );
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = 'Failed to copy asset: ${e.message}';
      });
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(_statusMessage),
        ),
      ),
    );
  }
}
