import 'package:flutter/material.dart';
import 'dart:io';

class MediaFile {
  final File file;
  final bool isVideo;
  Color color1;
  Color? color2;
  double percentage;

  MediaFile({
    required this.file,
    required this.isVideo,
    required this.color1,
    this.color2,
    this.percentage = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'path': file.path,
        'isVideo': isVideo,
        'color1': color1.value,
        'color2': color2?.value,
        'percentage': percentage,
      };

  static MediaFile fromJson(Map<String, dynamic> json) {
    return MediaFile(
      file: File(json['path']),
      isVideo: json['isVideo'] ?? false,
      color1: json['color1'] != null ? Color(json['color1']) : Colors.grey.shade300,
      color2: json['color2'] != null ? Color(json['color2']) : null,
      percentage: (json['percentage'] ?? 1.0).toDouble(),
    );
  }
}