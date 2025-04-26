import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    Colors.yellow,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

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

  void removeMedia(int index) {
    setState(() {
      mediaFiles.removeAt(index);
    });
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
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Multimedia (${mediaFiles.length}/$maxMediaCount)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 20,
                      children: [
                        ...mediaFiles.asMap().entries.map((entry) {
                          int i = entry.key;
                          MediaFile file = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
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
                                Slider(
                                  value: file.percentage,
                                  min: 0,
                                  max: 1,
                                  onChanged: (val) => setState(() => file.percentage = val),
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
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
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
                child: Text('Guardar', style: TextStyle(fontSize: 16)),
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
