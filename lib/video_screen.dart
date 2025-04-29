// Reemplazo completo del archivo VideoScreen con concatenación robusta (sin guardar en galería)

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

  Future<File> _convertImageToVideo(File imageFile) async {
    final tempDir = await getTemporaryDirectory();
    final nameWithoutExtension = imageFile.uri.pathSegments.last.split('.').first;
    final videoPath = '${tempDir.path}/${nameWithoutExtension}_image.mp4';

    final command = [
      '-loop', '1',
      '-i', imageFile.path,
      '-f', 'lavfi',
      '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100',
      '-t', '2',
      '-r', '30',
      '-vf', 'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2',
      '-c:v', 'libx264',
      '-b:v', '1500k',
      '-pix_fmt', 'yuv420p',
      '-shortest',
      '-movflags', '+faststart',
      '-y',
      videoPath,
    ].join(' ');

    await FFmpegKit.execute(command);
    return File(videoPath);
  }

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

  Future<bool> _checkHasAudio(File file) async {
    final session = await FFmpegKit.execute('-i "${file.path}"');
    final output = await session.getAllLogsAsString();
    return output?.contains('Audio:') ?? false;
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

  List<File> finalVideos = [];

  for (final file in mediaFiles) {
    if (file.path.toLowerCase().endsWith('.mp4')) {
      finalVideos.add(file);
    } else if (file.path.toLowerCase().endsWith('.jpg') || file.path.toLowerCase().endsWith('.jpeg') || file.path.toLowerCase().endsWith('.png')) {
      final videoFromImage = await _convertImageToVideo(file);
      finalVideos.add(videoFromImage);
    }
  }

  // Construye input.txt
  String inputContent = '';
  for (final file in finalVideos) {
    if (file.existsSync()) {
      inputContent += "file '${file.path}'\n";
    } else {
      print('⚠️ Excluido por no existir: ${file.path}');
    }
  }

  if (inputContent.trim().isEmpty) {
    _stopFakeProgress();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No hay vídeos válidos.')));
    return;
  }

  await inputFile.writeAsString(inputContent);
  print('📄 input.txt:\n$inputContent');

  // Comando robusto con demuxer
  final ffmpegCommand = "-f concat -safe 0 -i ${inputFile.path} -c copy -y ${videoOutput.path}";

  await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
    final logs = await session.getAllLogsAsString();
    print('📋 FFmpeg logs:\n$logs');

    _stopFakeProgress();

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      print('✅ Video creado: ${videoOutput.path}');
      setState(() {
        generatedVideoFile = videoOutput;
      });

      if (mounted) {
        _showVideoReadyDialog();
      }
    } else {
      print('❌ Error al generar el video');
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
        mediaFiles.add(media.file);
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