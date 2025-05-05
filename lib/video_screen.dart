// Reemplazo completo del archivo VideoScreen con concatenación robusta (sin guardar en galería)

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';


class VideoScreen extends StatefulWidget {
  final Map<DateTime, Map<String, dynamic>> dayData;

  const VideoScreen({Key? key, required this.dayData}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List<DateTime> selectedDays = [];
  int maxDurationSeconds = 60; // Para el slider
  bool includePhotos = true;   // Checkbox incluir fotos
  bool includeVideos = true;   // Checkbox incluir videos
  String rangeOption = 'Mes completo';
  List<String> selectedEmotions = [];
  bool shuffleMedia = false;
  bool isGenerating = false;
  double fakeProgress = 0.0;
  Timer? _progressTimer;
  File? generatedVideoFile;

  Future<File> _normalizeVideo(File inputFile) async {
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


  void _openCalendarDialog() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        final normalized = DateTime(picked.year, picked.month, picked.day);
        if (!selectedDays.any((d) =>
            d.year == normalized.year &&
            d.month == normalized.month &&
            d.day == normalized.day)) {
          selectedDays.add(normalized);
        }
      });
    }
  }


Future<File> _convertImageToVideo(File imageFile) async {
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


  Future<List<File>> getAllMediaFilesInStorage() async {
  final tempDir = await getTemporaryDirectory();
  final files = tempDir.listSync(recursive: true)
      .whereType<File>()
      .toList();
  return files;
}

List<String> getValidMediaPaths(Map<DateTime, Map<String, dynamic>> dayData) {
  final validPaths = <String>[];

  dayData.forEach((date, data) {
    final mediaList = data['media'] as List<dynamic>? ?? [];
    for (final media in mediaList) {
      validPaths.add(media.file.path);
    }
  });

  return validPaths;
}

Future<void> cleanOrphanFiles(Map<DateTime, Map<String, dynamic>> dayData) async {
  final allFiles = await getAllMediaFilesInStorage();
  final validPaths = getValidMediaPaths(dayData);

  for (final file in allFiles) {
    if (!validPaths.contains(file.path)) {
      try {
        await file.delete();
        print('🗑️ Archivo huérfano eliminado: ${file.path}');
      } catch (e) {
        print('⚠️ Error al eliminar archivo: ${file.path}');
      }
    }
  }
}


  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    cleanOrphanFiles(widget.dayData);
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
                labelText: 'Tipo de video',
                border: OutlineInputBorder(),
              ),
            ),
            if (rangeOption == 'Seleccionar días concretos') ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: isGenerating ? null : _openCalendarDialog,
                child: Text('Seleccionar días en calendario'),
              ),
            ],
            SizedBox(height: 24),
            Text('Duración máxima del video (segundos)', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: maxDurationSeconds.toDouble(),
              min: 10,
              max: 60,
              divisions: 10,
              label: '$maxDurationSeconds s',
              onChanged: isGenerating ? null : (value) {
                setState(() => maxDurationSeconds = value.toInt());
              },
            ),

            SizedBox(height: 24),

            CheckboxListTile(
              title: Text('Incluir fotos'),
              value: includePhotos,
              onChanged: isGenerating ? null : (val) {
                setState(() => includePhotos = val ?? true);
              },
            ),
            CheckboxListTile(
              title: Text('Incluir vídeos'),
              value: includeVideos,
              onChanged: isGenerating ? null : (val) {
                setState(() => includeVideos = val ?? true);
              },
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

  List<File> finalVideos = [];

  for (final file in mediaFiles) {
    if (file.path.toLowerCase().endsWith('.mp4')) {
      final normalized = await _normalizeVideo(file);
      finalVideos.add(normalized);
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
  final ffmpegCommand = "-f concat -safe 0 -i ${inputFile.path} -c:v mpeg4 -b:v 1000k -c:a aac -b:a 128k -pix_fmt yuv420p -t $maxDurationSeconds -y ${videoOutput.path}";

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
    List<MapEntry<DateTime, Map<String, dynamic>>> allDays = widget.dayData.entries.toList();
    List<MapEntry<DateTime, Map<String, dynamic>>> filteredDays = [];

    if (rangeOption == 'Mes completo') {
      final now = DateTime.now();
      filteredDays = allDays.where((entry) =>
        entry.key.month == now.month && entry.key.year == now.year
      ).toList();
    } else if (rangeOption == 'Seleccionar días concretos') {
      filteredDays = allDays.where((entry) => 
        selectedDays.any((selected) =>
          selected.year == entry.key.year &&
          selected.month == entry.key.month &&
          selected.day == entry.key.day
        )
      ).toList();
    }

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
        final file = media.file;
        final isVideo = file.path.toLowerCase().endsWith('.mp4');
        final isPhoto = file.path.toLowerCase().endsWith('.jpg') ||
                        file.path.toLowerCase().endsWith('.jpeg') ||
                        file.path.toLowerCase().endsWith('.png');
        if ((isVideo && includeVideos) || (isPhoto && includePhotos)) {
          mediaFiles.add(file);
        }
      }
    }

    if (shuffleMedia) {
      mediaFiles.shuffle();
    }

    return mediaFiles;
  }

  bool _colorMatchesEmotion(Color color) {
    final Map<String, Color> emotionColorMap = {
      'Alegría': Color(0xFFF4C430),
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

  final controller = VideoPlayerController.file(generatedVideoFile!);
  await controller.initialize();

  if (ModalRoute.of(context)?.isCurrent ?? false) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¡Vídeo generado!'),
        content: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Cierra el diálogo
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullscreenVideoPage(file: generatedVideoFile!),
              ),
            );
          },
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Share.shareXFiles(
                [XFile(generatedVideoFile!.path)],
                text: 'Mira este recuerdo 😊\n Video generado con EMOODIARIO, la mejor app para saber lo que sientes.\n <Enlace de Play Store>',
              );
            },
            child: Text('Compartir'),
          ),
        ],
      ),
    );
    controller.play();
  } else {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'video_ready_channel',
      'Vídeos generados',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

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

class FullscreenVideoPage extends StatefulWidget {
  final File file;
  const FullscreenVideoPage({required this.file});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late VideoPlayerController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Compartir video'),
                onTap: () {
                  Navigator.pop(context);
                  Share.shareXFiles([XFile(widget.file.path)], text: 'Mira este recuerdo 😊');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Reproducción completa'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          )
        ],
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.black,
        ),
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
      ),
    );
  }
}