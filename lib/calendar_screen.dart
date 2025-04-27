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

  Map<DateTime, Map<String, dynamic>> dayData = {};


late PageController _pageController;
@override
void initState() {
  super.initState();
  _pageController = PageController();
  final box = Hive.box('emotionsBox');
  final Map<DateTime, Map<String, dynamic>> loadedData = {};

  for (final key in box.keys) {
    final raw = box.get(key);

    if (raw is Map) {
      final date = DateTime.tryParse(key);
      if (date != null) {
        loadedData[date] = {
          'title': raw['title'] ?? '',
          'phrase': raw['phrase'] ?? '',
          'media': (raw['media'] as List?)?.map((m) {
            if (m is Map) {
              return MediaFile.fromJson(Map<String, dynamic>.from(m));
            } else {
              return null;
            }
          }).whereType<MediaFile>().toList() ?? [],
        };
      }
    }
  }

  setState(() {
    dayData = loadedData;
  });
}

  @override
  void dispose(){
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Map<Color, double> calcularColoresDelDia(DateTime date) {
    final mediaList = dayData[date]?['media'] ?? [];
    final Map<Color, double> colorSum = {};

    for (final media in mediaList) {
      if (media.color1 != null) {
        colorSum[media.color1] = (colorSum[media.color1] ?? 0) + (media.color2 == null ? 1.0 : media.percentage);
      }
      if (media.color2 != null) {
        colorSum[media.color2!] = (colorSum[media.color2!] ?? 0) + (1.0 - media.percentage);
      }
    }

    final sorted = colorSum.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {for (var e in sorted) e.key: e.value};
  }

  Color getColor1ForDay(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    final colores = calcularColoresDelDia(date);
    return colores.isNotEmpty ? colores.keys.first : Colors.grey.shade300;
  }

  Color? getColor2ForDay(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    final colores = calcularColoresDelDia(date);
    return colores.length > 1 ? colores.keys.elementAt(1) : null;
  }

  double getPercentageForDay(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    final colores = calcularColoresDelDia(date);
    if (colores.length >= 2) {
      final total = colores.values.elementAt(0) + colores.values.elementAt(1);
      return colores.values.elementAt(0) / total;
    }
    return 1.0;
  }

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

Widget _buildEmotionPreview(int day) {
  final date = DateTime(_focusedDate.year, _focusedDate.month, day);
  final data = dayData[date];
  final mediaList = data?['media'] ?? [];

  if (_selectedDay != day) _currentMediaIndex = 0;

  final color1 = getColor1ForDay(day);
  final color2 = getColor2ForDay(day);
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
            initialColor1: color1,
            initialColor2: color2,
            initialPercentage: getPercentageForDay(day),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: currentMedia != null
                    ? FutureBuilder<File?>(
                        key: ValueKey(currentMedia.file.path),
                        future: currentMedia.isVideo
                            ? getVideoThumbnail(currentMedia.file)
                            : Future.value(currentMedia.file),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                snapshot.data!,
                                fit: BoxFit.cover,
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
                    bool isActive = index == _currentMediaIndex;
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
  final Color color1;
  final Color? color2;
  final double percentage;

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
