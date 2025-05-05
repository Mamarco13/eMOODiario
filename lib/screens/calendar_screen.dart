import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'video_screen.dart';
import '../models/media_file.dart';
import '../utils/emotion_utils.dart';
import '../widgets/emotion_preview_card.dart';
import '../widgets/emotion_calendar.dart';



class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  DateTime _focusedDate = DateTime.now();
  int? _selectedDay;
  DateTime? _selectedDayReference;
  int? _selectedPreviewDay;
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
      final coloresDelDia = calcularColoresDelDia(date, dayData);
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

  @override
  Widget build(BuildContext context) {
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
            if (_selectedPreviewDay != null)
              EmotionPreviewCard(
                day: _selectedPreviewDay!,
                selectedDayReference: _selectedDayReference!,
                dayData: dayData,
                onDayUpdated: (date, newData) {
                  setState(() {
                    dayData[date] = newData;
                  });
                },
              ),
            EmotionCalendar(
              focusedDate: _focusedDate,
              selectedDay: _selectedDay,
              selectedDayReference: _selectedDayReference,
              dayData: dayData,
              isForward: isForward,
              previousMonth: previousMonth,
              onDaySelected: (int day) {
                setState(() {
                  _selectedDay = day;
                  _selectedPreviewDay = day;
                  _selectedDayReference = DateTime(_focusedDate.year, _focusedDate.month, day);
                });
              },
              onMonthChanged: (DateTime newDate) {
                setState(() {
                  isForward = newDate.month > previousMonth;
                  previousMonth = newDate.month;
                  _focusedDate = newDate;
                });
                updateDominantEmotionColor();
              },
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