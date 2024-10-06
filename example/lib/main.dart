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

  @override
  void initState() {
    super.initState();
    copyAssetToLocal();
  }

  Future<void> copyAssetToLocal() async {
    String status;
    try {
      const assetName = 'example.json';
      const targetPath = 'example.json';

      await LargeFileHandler().copyAssetToLocalStorage(
        assetName: assetName,
        targetPath: targetPath,
      );
      status = 'File copied successfully to $targetPath';
    } on PlatformException catch (e) {
      status = 'Failed to copy asset: ${e.message}';
    }

    if (!mounted) return;

    setState(() {
      _statusMessage = status;
    });
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
