import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../screens/edit_day_screen.dart';
import '../screens/fullscreen_image_page.dart';
import '../models/media_file.dart';
import '../utils/emotion_utils.dart';

class EmotionPreviewCard extends StatefulWidget {
  final int day;
  final DateTime selectedDayReference;
  final Map<DateTime, Map<String, dynamic>> dayData;
  final void Function(DateTime, Map<String, dynamic>) onDayUpdated;

  const EmotionPreviewCard({
    required this.day,
    required this.selectedDayReference,
    required this.dayData,
    required this.onDayUpdated,
  });

  @override
  State<EmotionPreviewCard> createState() => _EmotionPreviewCardState();
}

class _EmotionPreviewCardState extends State<EmotionPreviewCard> {
  int _currentMediaIndex = 0;
  bool _isHolding = false;

  Future<File?> getVideoThumbnail(File videoFile) async {
    final tempDir = Directory.systemTemp;
    final thumb = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 480,
      quality: 95,
    );
    if (thumb != null) {
      return File(thumb);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime(widget.selectedDayReference.year, widget.selectedDayReference.month, widget.day);
    final data = widget.dayData[date];
    final mediaList = data?['media'] ?? [];

    final color1 = getColor1ForDate(date, widget.dayData);
    final color2 = getColor2ForDate(date, widget.dayData);
    final gradient = color2 != null
        ? LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [color1.withOpacity(0.5), color2.withOpacity(0.5)])
        : LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [color1.withOpacity(0.5), color1.withOpacity(0.3)]);

    final currentMedia = mediaList.isNotEmpty ? mediaList[_currentMediaIndex % mediaList.length] : null;

    return GestureDetector(
      onDoubleTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditDayScreen(
              day: widget.day,
              date: date,
              initialColor1: color1,
              initialColor2: color2,
              initialPercentage: getPercentageForDate(date, widget.dayData),
            ),
            settings: RouteSettings(
              arguments: {
                'title': data?['title'],
                'phrase': data?['phrase'],
                'media': data?['media']?.map((m) => m.toJson()).toList() ?? [],
              },
            ),
          ),
        );

        if (result != null && result is Map<String, dynamic>) {
          final parsedData = {
            'title': result['title'],
            'phrase': result['phrase'],
            'media': (result['media'] as List).map((p) => MediaFile.fromJson(Map<String, dynamic>.from(p))).toList(),
          };

          final storageData = {
            'title': result['title'],
            'phrase': result['phrase'],
            'media': result['media'],
          };

          Hive.box('emotionsBox').put(date.toString(), storageData);
          widget.onDayUpdated(date, parsedData);
        }
      },
      onTap: () {
        if (currentMedia != null) {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => FullScreenImagePage(
                mediaList: mediaList,
                initialIndex: _currentMediaIndex,
                title: data?['title'],
                phrase: data?['phrase'],
              ),
            ),
          );
        }
      },
      onHorizontalDragEnd: (details) {
        if (mediaList.length > 1) {
          final velocity = details.primaryVelocity ?? 0.0;
          setState(() {
            if (velocity < 0) {
              _currentMediaIndex = ((_currentMediaIndex + 1) % mediaList.length).toInt();
            } else if (velocity > 0) {
              _currentMediaIndex = ((_currentMediaIndex - 1 + mediaList.length) % mediaList.length).toInt();
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 400),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: currentMedia != null
                      ? FutureBuilder<File?>(
                          key: ValueKey(currentMedia.file.path),
                          future: currentMedia.isVideo ? getVideoThumbnail(currentMedia.file) : Future.value(currentMedia.file),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Hero(
                                  tag: currentMedia.file.path,
                                  child: Image.file(snapshot.data!, fit: BoxFit.cover),
                                ),
                                if (currentMedia.isVideo && !_isHolding)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.8), size: 28),
                                  ),
                              ],
                            );
                          },
                        )
                      : Container(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: gradient,
                ),
              ),
              if (!_isHolding)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: List.generate(mediaList.length, (index) {
                      final isActive = index == _currentMediaIndex;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 10 : 6,
                        height: isActive ? 10 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      );
                    }),
                  ),
                ),
              if (!_isHolding)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(date),
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        data?['title'] ?? 'Sin título',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        data?['phrase'] ?? 'Sin descripción',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}