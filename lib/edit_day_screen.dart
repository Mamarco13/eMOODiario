import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';

//Colores mejorados
const Color softYellow = Color(0xFFF4C430);// Alegría - amarillo dorado
const Color softRed = Color.fromARGB(255, 253, 27, 27);    // Ira - rojo fuerte
const Color softBlue = Colors.blueAccent;   // Tristeza - azul vivo
const Color softPink = Color.fromARGB(255, 250, 127, 182);   // Enamoramiento - rosa intenso
const Color softOrange = Color.fromARGB(255, 255, 168, 38); // Ansiedad - naranja mandarina
const Color softPurple = Colors.purple; // Miedo - morado fuerte




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

class EditDayScreen extends StatefulWidget {
  final int day;
  final DateTime date;
  final Color initialColor1;
  final Color? initialColor2;
  final double initialPercentage;

  const EditDayScreen({
    required this.day,
    required this.date,
    required this.initialColor1,
    this.initialColor2,
    required this.initialPercentage,
  });

  @override
  State<EditDayScreen> createState() => _EditDayScreenState();
}

class _EditDayScreenState extends State<EditDayScreen> {
  String title = '';
  String phrase = '';
  List<MediaFile> mediaFiles = [];
  final titleController = TextEditingController();
  final phraseController = TextEditingController();
  final picker = ImagePicker();
  final maxMediaCount = 3;

  final List<Color> availableColors = [
    softYellow,
    softRed,
    softBlue,
    softPink,
    softOrange,
    softPurple,
  ];

  final Map<Color, String> colorToEmotion = {
    softYellow: 'Alegría',
    softRed: 'Ira',
    softBlue: 'Tristeza',
    softPink: 'Enamoramiento',
    softOrange: 'Ansiedad',
    softPurple: 'Miedo',
};


  @override
  void dispose() {
    titleController.dispose();
    phraseController.dispose();
    super.dispose();
  }

  Future<void> pickMedia({bool fromCamera = false, bool isVideo = false}) async {
    final pickedFile = isVideo
        ? await picker.pickVideo(source: fromCamera ? ImageSource.camera : ImageSource.gallery)
        : await picker.pickImage(source: fromCamera ? ImageSource.camera : ImageSource.gallery);

    if (pickedFile != null && mediaFiles.length < maxMediaCount) {
      setState(() {
        mediaFiles.add(MediaFile(
          file: File(pickedFile.path),
          isVideo: isVideo,
          color1: availableColors.first,
          color2: null,
          percentage: 1.0,
        ));
      });
    }
  }

  void removeMedia(int index) async {
    final media = mediaFiles[index];

    // 1. Eliminar físicamente el archivo si existe
    if (await media.file.exists()) {
      await media.file.delete();
      print('🗑️ Archivo físico eliminado: ${media.file.path}');
    }

    // 2. Eliminar del array de memoria
    setState(() {
      mediaFiles.removeAt(index);
    });

    // 3. (Opcional) Actualizar en Hive aquí si quieres que se guarde inmediatamente
    // O se puede actualizar solo al pulsar "Guardar" como ya haces en el botón "Guardar"
  }


  void toggleColorSelection(MediaFile media, Color color) {
    setState(() {
      if (media.color1 == color) {
        if (media.color2 != null) {
          media.color1 = media.color2!;
          media.color2 = null;
        }
      } else if (media.color2 == color) {
        media.color2 = null;
      } else if (media.color2 == null && media.color1 != color) {
        media.color2 = color;
      } else {
        media.color1 = color;
        media.color2 = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text('Editar Día ${widget.day}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Título', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              onChanged: (val) => title = val,
              decoration: InputDecoration(
                hintText: 'Escribe un título...'
              ),
            ),
            const SizedBox(height: 20),
            Text('Frase del día', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: phraseController,
              onChanged: (val) => phrase = val,
              decoration: InputDecoration(hintText: '¿Cómo te sentiste?'),
            ),
            const SizedBox(height: 30),
            Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400, // 👈 O el tamaño que quieras, 400px suele quedar bien en móvil
              ),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Multimedia (${mediaFiles.length}/$maxMediaCount)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          ...mediaFiles.asMap().entries.map((entry) {
                            int i = entry.key;
                            MediaFile file = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: file.isVideo
                                          ? FutureBuilder<String?>(
                                              future: VideoThumbnail.thumbnailFile(
                                                video: file.file.path,
                                                imageFormat: ImageFormat.PNG,
                                                maxWidth: 100,
                                                quality: 75,
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    color: Colors.grey.shade300,
                                                    child: Center(child: CircularProgressIndicator()),
                                                  );
                                                } else if (snapshot.hasData && snapshot.data != null) {
                                                  return Image.file(
                                                    File(snapshot.data!),
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  );
                                                } else {
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    color: Colors.grey,
                                                    child: Icon(Icons.videocam),
                                                  );
                                                }
                                              },
                                            )
                                          : Image.file(
                                              file.file,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                    ),

                                    if (file.isVideo)
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 24),
                                      ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => removeMedia(i),
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: availableColors.map((color) {
                                    final isSelected = color == file.color1 || color == file.color2;
                                    return GestureDetector(
                                      onTap: () => toggleColorSelection(file, color),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(width: 2, color: isSelected ? Colors.black : Colors.transparent),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (file.color2 != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('1', style: TextStyle(color: file.color1)),
                                      Text('2', style: TextStyle(color: file.color2))
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            colorToEmotion[file.color1] ?? '',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: file.color1),
                                          ),
                                          Text(
                                            colorToEmotion[file.color2!] ?? '',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: file.color2),
                                          ),
                                        ],
                                      ),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 8,
                                          activeTrackColor: file.color2 != null
                                              ? null
                                              : file.color1,
                                          inactiveTrackColor: file.color2 != null
                                              ? null
                                              : file.color1.withOpacity(0.3),
                                          trackShape: file.color2 != null
                                              ? _GradientSliderTrack(file.color1, file.color2!)
                                              : null,
                                        ),
                                        child: Slider(
                                          value: file.percentage,
                                          min: 0,
                                          max: 1,
                                          onChanged: (val) => setState(() => file.percentage = val),
                                        ),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            );
                          }).toList(),
                          if (mediaFiles.length < maxMediaCount)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMediaButton(Icons.photo, () => pickMedia(fromCamera: false)),
                                SizedBox(width: 8),
                                _buildMediaButton(Icons.camera_alt, () => pickMedia(fromCamera: true)),
                                SizedBox(width: 8),
                                _buildMediaButton(Icons.videocam, () => pickMedia(fromCamera: false, isVideo: true)),
                              ],
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          )
        ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context, {
                    'title': title,
                    'phrase': phrase,
                    'media': mediaFiles.map((m) => m.toJson()).toList()
                  });
                },
                child: Text('Guardar', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 30, color: Colors.black54),
      ),
    );
  }

  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args != null) {
    title = args['title'] ?? '';
    phrase = args['phrase'] ?? '';
    titleController.text = title;
    phraseController.text = phrase;

    final mediaData = args['media'] as List?;
    if (mediaData != null) {
      mediaFiles = mediaData.map((e) {
        if (e is Map) {
          return MediaFile.fromJson(Map<String, dynamic>.from(e));
        } else {
          return null;
        }
      }).whereType<MediaFile>().toList();
    }
  }
}
}

class _GradientSliderTrack extends SliderTrackShape {
  final Color color1;
  final Color color2;

  _GradientSliderTrack(this.color1, this.color2);

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required Offset thumbCenter,
  }) {
    final Paint activePaint = Paint()..color = color1;
    final Paint inactivePaint = Paint()..color = color2 ?? color1.withOpacity(0.3);

    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackRadius = Radius.circular(trackHeight / 2);

    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackRight = trackLeft + parentBox.size.width;
    final double trackCenter = thumbCenter.dx;

    final Rect activeTrackRect = Rect.fromLTRB(trackLeft, trackTop, trackCenter, trackTop + trackHeight);
    final Rect inactiveTrackRect = Rect.fromLTRB(trackCenter, trackTop, trackRight, trackTop + trackHeight);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeTrackRect, trackRadius),
      activePaint,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(inactiveTrackRect, trackRadius),
      inactivePaint,
    );
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

}

