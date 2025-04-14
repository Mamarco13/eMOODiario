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

  final picker = ImagePicker();
  final maxMediaCount = 3;

  @override
  void initState() {
    super.initState();
    selectedColor1 = widget.initialColor1;
    selectedColor2 = widget.initialColor2;
    percentage = widget.initialPercentage;
  }

  Future<void> pickMedia() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
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
              onChanged: (val) => setState(() => title = val),
              decoration: InputDecoration(hintText: 'Escribe un título...'),
            ),
            SizedBox(height: 16),
            Text('Frase del día'),
            TextField(
              onChanged: (val) => setState(() => phrase = val),
              decoration: InputDecoration(hintText: '¿Cómo te sentiste?'),
            ),
            SizedBox(height: 16),
            Text('Selecciona emociones'),
            Row(
              children: [
                colorCircle(selectedColor1, (color) => setState(() => selectedColor1 = color)),
                SizedBox(width: 8),
                if (selectedColor2 != null)
                  colorCircle(selectedColor2!, (color) => setState(() => selectedColor2 = color)),
              ],
            ),
            SizedBox(height: 16),
            Text('Proporción entre emociones'),
            Slider(
              value: percentage,
              min: 0,
              max: 1,
              onChanged: (val) => setState(() => percentage = val),
            ),
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
                  GestureDetector(
                    onTap: pickMedia,
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: Icon(Icons.add),
                    ),
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

  Widget colorCircle(Color color, Function(Color) onTap) {
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(width: 2, color: Colors.black),
        ),
      ),
    );
  }
}