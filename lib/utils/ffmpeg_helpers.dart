import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/services.dart'; 

class FfmpegHelpers {
  static Future<String> copyAssetToTemp(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  static Future<File> normalizeVideo(File inputFile) async {
    final tempDir = await getTemporaryDirectory();
    final outputFile = File('${tempDir.path}/${inputFile.uri.pathSegments.last}_norm.mp4');

    final command = [
      '-i', inputFile.path,
      '-r', '30',
      '-vf', 'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2',
      '-c:v', 'mpeg4',
      '-b:v', '1000k',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-y', outputFile.path,
    ];

    print('🎞️ Normalizando video original:\n${command.join(' ')}');
    final session = await FFmpegKit.execute(command.join(' '));
    final returnCode = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputFile;
    } else {
      print('❌ Error al normalizar video:\n$logs');
      throw Exception('Error al normalizar video');
    }
  }

  static Future<File> convertImageToVideo(File imageFile) async {
    final tempDir = await getTemporaryDirectory();
    final nameWithoutExtension = imageFile.uri.pathSegments.last.split('.').first;
    final videoPath = '${tempDir.path}/${nameWithoutExtension}_image.mp4';

    if (!await imageFile.exists()) {
      throw Exception('Imagen no encontrada en: ${imageFile.path}');
    }

    final command = [
      '-loop', '1',
      '-i', imageFile.path,
      '-f', 'lavfi',
      '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100',
      '-t', '2',
      '-r', '30',
      '-vf', 'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2',
      '-c:v', 'mpeg4',
      '-b:v', '1000k',
      '-pix_fmt', 'yuv420p',
      '-shortest',
      '-movflags', '+faststart',
      '-y', videoPath,
    ];

    print('🎬 Ejecutando comando FFmpeg:\n${command.join(' ')}');

    final session = await FFmpegKit.execute(command.join(' '));

  final returnCode = await session.getReturnCode();
  final logs = await session.getAllLogsAsString();
  print('📋 FFmpeg logs:\n$logs');

  if (ReturnCode.isSuccess(returnCode)) {
    final file = File(videoPath);
    if (await file.exists()) {
      print('✅ Imagen convertida a video: $videoPath');
      return file;
    } else {
      throw Exception('El video generado no existe: $videoPath');
    }
  } else {
    throw Exception('Falló la conversión de imagen a video:\n$logs');
  }
}

  static Future<int> calcularDuracionTotal(List<File> mediaFiles) async {
    int totalSeconds = 0;

    for (final file in mediaFiles) {
      final isVideo = file.path.toLowerCase().endsWith('.mp4');
      if (isVideo) {
        final info = await FFmpegKit.executeWithArguments(['-i', file.path]);
        final logs = await info.getAllLogsAsString();
        final match = RegExp(r'Duration: (\d+):(\d+):(\d+.\d+)').firstMatch(logs.toString());
        if (match != null) {
          final hours = int.parse(match.group(1)!);
          final minutes = int.parse(match.group(2)!);
          final seconds = double.parse(match.group(3)!);
          totalSeconds += (hours * 3600 + minutes * 60 + seconds).round();
        }
      } else {
        totalSeconds += 2; // 2 segundos por imagen
      }
    }

    return totalSeconds;
  }
}
