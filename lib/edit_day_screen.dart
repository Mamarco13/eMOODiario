import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  late Color selectedColor1;
  Color? selectedColor2;
  double percentage = 1.0;
  String title = '';
  String phrase = '';
  List<File> mediaFiles = [];

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
  void initState() {
    super.initState();
    selectedColor1 = widget.initialColor1;
    selectedColor2 = widget.initialColor2;
    percentage = widget.initialPercentage;
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
      final mediaPaths = List<String>.from(args['media'] ?? []);
      mediaFiles = mediaPaths.map((path) => File(path)).toList();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    phraseController.dispose();
    super.dispose();
  }

  Future<void> pickMedia({bool fromCamera = false}) async {
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null && mediaFiles.length < maxMediaCount) {
      setState(() {
        mediaFiles.add(File(pickedFile.path));
      });
    }
  }

  void removeMedia(int index) {
    setState(() {
      mediaFiles.removeAt(index);
    });
  }

  void toggleColorSelection(Color color) {
    setState(() {
      if (selectedColor1 == color) {
        if (selectedColor2 != null) {
          selectedColor1 = selectedColor2!;
          selectedColor2 = null;
        }
      } else if (selectedColor2 == color) {
        selectedColor2 = null;
      } else if (selectedColor2 == null && selectedColor1 != color) {
        selectedColor2 = color;
      } else {
        selectedColor1 = color;
        selectedColor2 = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Día ${widget.day}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Título'),
            TextField(
              controller: titleController,
              onChanged: (val) => title = val,
              decoration: InputDecoration(hintText: 'Escribe un título...'),
            ),
            SizedBox(height: 16),
            Text('Frase del día'),
            TextField(
              controller: phraseController,
              onChanged: (val) => phrase = val,
              decoration: InputDecoration(hintText: '¿Cómo te sentiste?'),
            ),
            SizedBox(height: 16),
            Text('Selecciona emociones (máx. 2)'),
            Wrap(
              spacing: 8,
              children: availableColors.map((color) {
                final isSelected = color == selectedColor1 || color == selectedColor2;
                return GestureDetector(
                  onTap: () => toggleColorSelection(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(width: 2, color: isSelected ? Colors.black : Colors.transparent),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            if (selectedColor2 != null) ...[
              Text('Proporción entre emociones'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Emoción 1', style: TextStyle(color: selectedColor1)),
                  Text('Emoción 2', style: TextStyle(color: selectedColor2)),
                ],
              ),
              Slider(
                value: percentage,
                min: 0,
                max: 1,
                onChanged: (val) => setState(() => percentage = val),
              ),
              Center(
                child: CustomPaint(
                  size: Size(80, 80),
                  painter: _HorizontalSplitCirclePainter(
                    color1: selectedColor1,
                    color2: selectedColor2!,
                    percentage: percentage,
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),
            Text('Multimedia (${mediaFiles.length}/$maxMediaCount)'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < mediaFiles.length; i++)
                  Stack(
                    children: [
                      Image.file(mediaFiles[i], width: 100, height: 100, fit: BoxFit.cover),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => removeMedia(i),
                        ),
                      )
                    ],
                  ),
                if (mediaFiles.length < maxMediaCount)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => pickMedia(fromCamera: false),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.photo),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => pickMedia(fromCamera: true),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  )
              ],
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'title': title,
                    'phrase': phrase,
                    'color1': selectedColor1.value,
                    'color2': selectedColor2?.value,
                    'percentage': percentage,
                    'media': mediaFiles.map((f) => f.path).toList(),
                  });
                },
                child: Text('Guardar'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _HorizontalSplitCirclePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double percentage;

  _HorizontalSplitCirclePainter({
    required this.color1,
    required this.color2,
    required this.percentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final height1 = size.height * percentage;
    final height2 = size.height * (1 - percentage);

    final rect1 = Rect.fromLTWH(0, size.height - height1, size.width, height1);
    final rect2 = Rect.fromLTWH(0, 0, size.width, height2);

    final rrect1 = RRect.fromRectAndRadius(rect1, Radius.circular(size.width / 2));
    final rrect2 = RRect.fromRectAndRadius(rect2, Radius.circular(size.width / 2));

    canvas.drawRRect(rrect2, paint2);
    canvas.drawRRect(rrect1, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}