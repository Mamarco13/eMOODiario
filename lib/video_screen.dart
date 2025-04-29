import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class VideoScreen extends StatefulWidget {
  final Map<DateTime, Map<String, dynamic>> dayData;

  const VideoScreen({Key? key, required this.dayData}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  String rangeOption = 'Mes completo';
  List<String> selectedEmotions = [];
  bool shuffleMedia = false;
  bool isGenerating = false;
  double fakeProgress = 0.0;
  Timer? _progressTimer;
  File? generatedVideoFile;

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await notificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Video Recuerdo'),
        backgroundColor: Colors.blueGrey.shade300,
      ),
      backgroundColor: Colors.blueGrey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('¿Qué quieres incluir?', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: rangeOption,
              items: [
                'Mes completo',
                'Rango de días',
                'Seleccionar días concretos',
              ].map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: isGenerating ? null : (value) {
                if (value != null) {
                  setState(() {
                    rangeOption = value;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Duración',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text('Filtrar por emociones (opcional)', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Alegría', 'Ira', 'Tristeza', 'Enamoramiento', 'Ansiedad', 'Miedo'
              ].map((emotion) {
                final selected = selectedEmotions.contains(emotion);
                return FilterChip(
                  label: Text(emotion),
                  selected: selected,
                  onSelected: isGenerating ? null : (val) {
                    setState(() {
                      if (val) {
                        selectedEmotions.add(emotion);
                      } else {
                        selectedEmotions.remove(emotion);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            SwitchListTile(
              value: shuffleMedia,
              onChanged: isGenerating ? null : (val) {
                setState(() {
                  shuffleMedia = val;
                });
              },
              title: Text('Orden aleatorio'),
            ),
            SizedBox(height: 32),
            if (isGenerating) ...[
              Text('Generando video...', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              LinearProgressIndicator(value: fakeProgress),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _startGeneratingVideo,
                icon: Icon(Icons.movie_filter_outlined),
                label: Text('Generar Video'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.blueGrey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _startGeneratingVideo() async {
    setState(() {
      isGenerating = true;
      fakeProgress = 0.0;
    });

    _startFakeProgress();

    List<File> mediaFiles = _prepareMediaFiles();

    if (mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No hay archivos multimedia para crear el video.')));
      _stopFakeProgress();
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final inputFile = File('${tempDir.path}/input.txt');
    final videoOutput = File('${tempDir.path}/video_recuerdo_${DateTime.now().millisecondsSinceEpoch}.mp4');

    String inputContent = '';
    for (final file in mediaFiles) {
      inputContent += "file '${file.path.replaceAll("'", "\\'")}'\n";
    }
    await inputFile.writeAsString(inputContent);

    final ffmpegCommand = "-f concat -safe 0 -i ${inputFile.path} -c:v libx264 -preset veryfast ${videoOutput.path}";

    await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
      _stopFakeProgress();

      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        print('Video creado: ${videoOutput.path}');
        setState(() {
          generatedVideoFile = videoOutput;
        });

        if (mounted) {
          _showVideoReadyDialog();
        }
      } else {
        print('Error al generar el video');
      }
    });
  }

  void _startFakeProgress() {
    _progressTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        fakeProgress += 0.05;
        if (fakeProgress > 1.0) fakeProgress = 1.0;
      });
    });
  }

  void _stopFakeProgress() {
    _progressTimer?.cancel();
    setState(() {
      isGenerating = false;
      fakeProgress = 1.0;
    });
  }

  List<File> _prepareMediaFiles() {
    List<MapEntry<DateTime, Map<String, dynamic>>> filteredDays = widget.dayData.entries.toList();

    if (selectedEmotions.isNotEmpty) {
      filteredDays = filteredDays.where((entry) {
        final mediaList = entry.value['media'] as List<dynamic>? ?? [];
        return mediaList.any((media) {
          final color1 = media.color1;
          final color2 = media.color2;
          return _colorMatchesEmotion(color1) || (color2 != null && _colorMatchesEmotion(color2));
        });
      }).toList();
    }

    List<File> mediaFiles = [];
    for (final entry in filteredDays) {
      final mediaList = entry.value['media'] as List<dynamic>? ?? [];
      for (final media in mediaList) {
        mediaFiles.add(File(media['path']));
      }
    }

    if (shuffleMedia) {
      mediaFiles.shuffle();
    }

    return mediaFiles;
  }

  bool _colorMatchesEmotion(Color color) {
    final Map<String, Color> emotionColorMap = {
      'Alegría': Colors.yellow,
      'Ira': Color.fromARGB(255, 253, 27, 27),
      'Tristeza': Colors.blueAccent,
      'Enamoramiento': Color.fromARGB(255, 250, 127, 182),
      'Ansiedad': Color.fromARGB(255, 255, 168, 38),
      'Miedo': Colors.purple,
    };

    return selectedEmotions.any((emotion) => emotionColorMap[emotion]?.value == color.value);
  }

  void _showVideoReadyDialog() async {
    if (generatedVideoFile == null) return;

    if (ModalRoute.of(context)?.isCurrent ?? false) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('¡Vídeo generado!'),
          content: Text('Tu vídeo está listo. ¿Quieres verlo ahora?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                OpenFile.open(generatedVideoFile!.path);
              },
              child: Text('Ver vídeo'),
            ),
          ],
        ),
      );
    } else {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'video_ready_channel',
        'Vídeos generados',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await notificationsPlugin.show(
        0,
        'Vídeo listo',
        '¡Tu vídeo emocional está generado!',
        notificationDetails,
      );
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}
