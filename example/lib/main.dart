import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:live_photos/live_photos.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _dio = Dio();

  Future<void> saveWallpaper(String path) async {
    final permission = await Gal.requestAccess(toAlbum: true);
    if (!permission) return;
    final cacheDir = await getApplicationDocumentsDirectory();
    print("asdklandan");
    print(cacheDir.path);

    final videoFileName = path.fileName;
    final videoFileNameExt = path.fileExtension;
    File videoFile = File("${cacheDir.path}/$videoFileName");
    if (await videoFile.exists()) await videoFile.delete();
    print("here ${videoFile.path}");
    try {
      await _dio.download(
        path,
        videoFile.path,
      );
      if (!(await videoFile.exists())) {
        throw Exception("cannot download video or photo files");
      }
      if (videoFileNameExt != 'mp4') {
        videoFile = await convertVideoToMp4(
          inputFile: videoFile,
          outputFile: File("${cacheDir.path}/a.mp4"),
        );
      }
      await LivePhotos.generate(localPath: videoFile.path).then((value) {
        print("complete $value");
      });
    } catch (e) {
      print("failed to save wallpaper: $e");
    }
  }

  Future<File> convertVideoToMp4({
    required File inputFile,
    required File outputFile,
  }) async {
    if (await outputFile.exists()) await outputFile.delete();
    final ffmpegCommand = [
      '-i',
      inputFile.path,
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-c:a',
      'copy',
      outputFile.path,
    ];
    if (kDebugMode) {
      print("[FFmpegSource] executing command: ${ffmpegCommand.join(" ")}");
    }
    await FFmpegKit.execute(ffmpegCommand.join(" "));
    if (!(await outputFile.exists())) {
      throw Exception("Output file not exists after execute ffmpeg command");
    }
    return outputFile;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                saveWallpaper(
                  "https://ringtones-for-iphone.s3.amazonaws.com/media/wallpaper/original/16774253397529621364408.webm",
                );
              },
              child: Text(
                ("Do"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                saveWallpaper(
                  "https://ringtones-for-iphone.s3.amazonaws.com/media/wallpaper/original/16572080208999900080800.mov",
                );
              },
              child: Text(
                ("Do2"),
              ),
            )
          ],
        )),
      ),
    );
  }
}

extension FileStringExtension on String {
  String get fileName {
    return split('/').lastOrNull ?? "";
  }

  String get fileExtension {
    return split('.').lastOrNull ?? "";
  }
}
