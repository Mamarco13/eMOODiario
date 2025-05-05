import 'package:flutter/material.dart';
import '../widgets/emotion_glass_day.dart';
import 'edit_day_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'fullscreen_image_page.dart';
import 'package:flutter/services.dart';
import 'video_screen.dart';
import '../models/media_file.dart';


class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  DateTime _focusedDate = DateTime.now();
  int? _selectedDay;
  DateTime? _selectedDayReference;
  int? _selectedPreviewDay;
  int _currentMediaIndex = 0;
  bool _isHolding = false;
  VideoPlayerController? _videoController;
  late PageController _pageController;
  Color dominantEmotionColor = Colors.white;
  int previousMonth = DateTime.now().month;
  bool isForward = true;




  Map<DateTime, Map<String, dynamic>> dayData = {};

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
      final today = DateTime.now();
      _selectedDay = today.day;
      _selectedPreviewDay = today.day;
      _selectedDayReference = today;
      _focusedDate = DateTime(today.year, today.month);
      previousMonth = today.month;
    });
    updateDominantEmotionColor();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void updateDominantEmotionColor() {
    final Map<Color, double> emotionSum = {};

    //final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final totalDays = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final coloresDelDia = calcularColoresDelDia(date);
      for (final entry in coloresDelDia.entries) {
        emotionSum[entry.key] = (emotionSum[entry.key] ?? 0) + entry.value;
      }
    }

    if (emotionSum.isNotEmpty) {
      final sorted = emotionSum.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      setState(() {
        dominantEmotionColor = sorted.first.key;
      });
    } else {
      setState(() {
        dominantEmotionColor = Colors.white;
      });
    }
  }


  Map<Color, double> calcularColoresDelDia(DateTime date) {
    final mediaList = dayData[date]?['media'] ?? [];
    final Map<Color, double> colorSum = {};

    for (final media in mediaList) {
      colorSum[media.color1] = (colorSum[media.color1] ?? 0) + (media.color2 == null ? 1.0 : media.percentage);
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

  Color getColor1ForDate(DateTime date) {
    final colores = calcularColoresDelDia(date);
    return colores.isNotEmpty ? colores.keys.first : Colors.grey.shade300;
  }

  Color? getColor2ForDate(DateTime date) {
    final colores = calcularColoresDelDia(date);
    return colores.length > 1 ? colores.keys.elementAt(1) : null;
  }

  double getPercentageForDate(DateTime date) {
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
    final date = DateTime(
      _selectedDayReference!.year,
      _selectedDayReference!.month,
      day,
    );
    final data = dayData[date];
    final mediaList = data?['media'] ?? [];

    if (_selectedDay != day) _currentMediaIndex = 0;

    final color1 = getColor1ForDate(date);
    final color2 = getColor2ForDate(date);
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
          day: day,
          date: date,
          initialColor1: color1,
          initialColor2: color2,
          initialPercentage: getPercentageForDate(date),
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
                            Hero(
                              tag: currentMedia.file.path,
                              child: Image.file(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
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
      final isSelected = _selectedDay != null && _selectedDayReference != null &&
    _selectedDay == day &&
    _focusedDate.month == _selectedDayReference!.month &&
    _focusedDate.year == _selectedDayReference!.year;

      final hasTwoEmotions = getColor2ForDay(day) != null;
      final double scaleFactor = isSelected ? (hasTwoEmotions ? 0.6 : 0.75) : 1.0;

      final widget = GestureDetector(
        onTap: () {
          setState(() {
            _selectedDay = day;
            _selectedPreviewDay = day;
            _selectedDayReference = DateTime(_focusedDate.year, _focusedDate.month, day);
          });
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: scaleFactor),
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: Offset(isForward ? 1.0 : -1.0, 0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          child: AppBar(
            key: ValueKey(dominantEmotionColor.value), // 👈 clave para que AnimatedSwitcher detecte el cambio
            backgroundColor: dominantEmotionColor.withOpacity(0.9),
            elevation: 0,
            centerTitle: true,
            title: Image.asset(
              'assets/EMOODIARIO.png',
              height: 65,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
      ),

      body: AnimatedContainer(
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        color: dominantEmotionColor.withOpacity(0.15), // 👈 Para que sea suave, no demasiado fuerte
        child: Column(
          children: [
            if (_selectedPreviewDay  != null) _buildEmotionPreview(_selectedPreviewDay!),
            Expanded(
              child: Column(
                children: [
                  // Nuevo header con flechas y mes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: () {
                            final newDate = DateTime(_focusedDate.year, _focusedDate.month - 1); // o -1 según el botón
                            setState(() {
                              isForward = newDate.month > previousMonth;
                              previousMonth = newDate.month;
                              _focusedDate = newDate;
                            });
                            updateDominantEmotionColor();

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
                            final newDate = DateTime(_focusedDate.year, _focusedDate.month + 1); // o -1 según el botón
                            setState(() {
                              isForward = newDate.month > previousMonth;
                              previousMonth = newDate.month;
                              _focusedDate = newDate;
                            });
                            updateDominantEmotionColor();
                          },
                        ),
                      ],
                    ),
                  ),
                  // Ahora el calendario
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 7 / 5.5, // 7 columnas y 6 filas
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GridView.count(
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 7,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: dayWidgets,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 12),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoScreen(
                                dayData: dayData,
                                selectedMonth: DateTime(_focusedDate.year, _focusedDate.month),
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.movie_creation_outlined, color: Colors.black), // Color negro del icono
                        label: Text(
                          "Crear Video",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,  // Fondo transparente
                          shadowColor: Colors.transparent,      // Sin sombra
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.black, width: 2), // Opcional: contorno negro bonito
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (_selectedDayReference != null &&
        (_selectedDayReference!.month != _focusedDate.month ||
         _selectedDayReference!.year != _focusedDate!.year))
    ? Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6.0, top: 12.0, right: 12.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _focusedDate = DateTime(
                  _selectedDayReference!.year,
                  _selectedDayReference!.month,
                );
                previousMonth = _focusedDate.month;
              });
              updateDominantEmotionColor();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                color: Colors.transparent,
              ),
              child: Icon(Icons.calendar_today, color: Colors.black),
            ),
          ),
        ),
      )
    : null,
    );
  }
}