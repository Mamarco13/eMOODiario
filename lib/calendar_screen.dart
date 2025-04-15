import 'package:flutter/material.dart';
import 'emotion_glass_day.dart';
import 'edit_day_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  DateTime _focusedDate = DateTime.now();
  int? _selectedDay;
  int _currentMediaIndex = 0;
  bool _isHolding = false;
  VideoPlayerController? _videoController;

  Future<File?> getVideoThumbnail(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
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

  Map<DateTime, Map<String, dynamic>> dayData = {};

  final List<String> weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('emotionsBox');
    final Map<DateTime, Map<String, dynamic>> loadedData = {};

    for (final key in box.keys) {
      final raw = box.get(key);
      final date = DateTime.parse(key);
      loadedData[date] = {
        'title': raw['title'],
        'phrase': raw['phrase'],
        'color1': Color(raw['color1']),
        'color2': raw['color2'] != null ? Color(raw['color2']) : null,
        'percentage': raw['percentage'],
        'media': (raw['media'] as List)
            .map((p) => p is Map ? MediaFile.fromJson(Map<String, dynamic>.from(p)) : MediaFile(file: File(p), isVideo: false))
            .toList(),
      };
    }

    setState(() {
      dayData = loadedData;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Color getColor1ForDay(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    return dayData[date]?['color1'] ?? Colors.grey.shade300;
  }

  Color? getColor2ForDay(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    return dayData[date]?['color2'];
  }

  double getPercentageForDay(int day, {bool isSelected = false}) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    final raw = dayData[date]?['percentage'] ?? 0.95;
    if (isSelected) {
      return 0.60;
    }
    return raw;
  }

  Widget _buildEmotionPreview(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    final data = dayData[date];
    final mediaList = data?['media'] ?? [];

    if (_selectedDay != day) _currentMediaIndex = 0;

    final color1 = data?['color1'] ?? Colors.grey.shade300;
    final color2 = data?['color2'];
    final gradient = color2 != null
        ? LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color1.withOpacity(0.5), color2.withOpacity(0.5)],
          )
        : LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color1.withOpacity(0.5), color1.withOpacity(0.3)],
          );

    final currentMedia = mediaList.isNotEmpty
        ? mediaList[_currentMediaIndex % mediaList.length]
        : null;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditDayScreen(
              day: day,
              date: date,
              initialColor1: data?['color1'] ?? Colors.yellow,
              initialColor2: data?['color2'],
              initialPercentage: data?['percentage'] ?? 1.0,
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
            'color1': Color(result['color1']),
            'color2': result['color2'] != null ? Color(result['color2']) : null,
            'percentage': result['percentage'],
            'media': (result['media'] as List).map((p) => MediaFile.fromJson(p)).toList(),
          };

          final storageData = {
            'title': result['title'],
            'phrase': result['phrase'],
            'color1': result['color1'],
            'color2': result['color2'],
            'percentage': result['percentage'],
            'media': result['media'],
          };

          Hive.box('emotionsBox').put(date.toString(), storageData);

          setState(() {
            dayData[date] = parsedData;
          });
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
      onLongPressStart: (_) async {
        if (currentMedia != null && currentMedia.isVideo) {
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(currentMedia.file);
          await _videoController!.initialize();
          _videoController!.setLooping(true);
          await _videoController!.play();
          setState(() => _isHolding = true);
        }
      },
      onLongPressEnd: (_) {
        _videoController?.pause();
        setState(() => _isHolding = false);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isHolding && _videoController != null && _videoController!.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: VideoPlayer(_videoController!),
                )
              else if (currentMedia != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FutureBuilder<File?>(
                    future: currentMedia.isVideo ? getVideoThumbnail(currentMedia.file) : Future.value(currentMedia.file),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return Stack(
                        children: [
                          Image.file(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            alignment: Alignment(0, -0.5),
                            width: double.infinity,
                            height: double.infinity,
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
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: gradient,
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        data?['title'] ?? 'Sin título',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final totalDaysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstWeekday = (firstDayOfMonth.weekday + 6) % 7;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= totalDaysInMonth; day++) {
      final isSelected = _selectedDay == day;
      final hasTwoEmotions = getColor2ForDay(day) != null;
      final double scaleFactor = isSelected ? (hasTwoEmotions ? 0.6 : 0.75) : 1.0;

      final widget = GestureDetector(
        onTap: () {
          setState(() {
            _selectedDay = day;
          });
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 1.0,
            end: scaleFactor,
          ),
          duration: Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          builder: (context, animatedScale, child) {
            return EmotionGlassDay(
              key: ValueKey('${day}_$isSelected'),
              day: day,
              color1: getColor1ForDay(day),
              color2: getColor2ForDay(day),
              percentage: getPercentageForDay(day),
              scaleHeight: animatedScale,
              animate: isSelected,
            );
          },
        ),
      );

      dayWidgets.add(widget);
    }

    return Scaffold(
      backgroundColor: Color(0xFFF3F6FD),
      appBar: AppBar(
        title: Text('Mis Recuerdos', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          if (_selectedDay != null) _buildEmotionPreview(_selectedDay!),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month - 1,
                      );
                      _selectedDay = null;
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'es_ES').format(_focusedDate).toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month + 1,
                      );
                      _selectedDay = null;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: dayWidgets,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MediaFile {
  final File file;
  final bool isVideo;

  MediaFile({required this.file, required this.isVideo});

  Map<String, dynamic> toJson() => {
        'path': file.path,
        'isVideo': isVideo,
      };

  static MediaFile fromJson(Map<String, dynamic> json) {
    return MediaFile(
      file: File(json['path']),
      isVideo: json['isVideo'] ?? false,
    );
  }
}
