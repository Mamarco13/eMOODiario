import 'package:flutter/material.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../models/media_file.dart';

class FullScreenImagePage extends StatefulWidget {
  final List<MediaFile> mediaList;
  final int initialIndex;
  final String? title;
  final String? phrase;

  const FullScreenImagePage({
    required this.mediaList,
    required this.initialIndex,
    this.title,
    this.phrase,
  });

  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late PageController _controller;
  late int _currentIndex;
  bool _showUI = true;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<File?> getVideoThumbnail(File videoFile) async {
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 500,
      quality: 75,
    );
    if (thumbPath != null) {
      return File(thumbPath);
    }
    return null;
  }

  Future<void> _downloadCurrentImage() async {
    final currentMedia = widget.mediaList[_currentIndex];
    final bytes = await currentMedia.file.readAsBytes();

    PermissionStatus status = await Permission.photos.request(); // 👈 NUEVO

    if (status.isGranted) {
      final directory = Directory('/storage/emulated/0/Pictures/MisRecuerdos');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String fileName = 'recuerdo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File newImage = File('${directory.path}/$fileName');
      await newImage.writeAsBytes(bytes);

      const MethodChannel('com.misrecuerdos.gallery')
          .invokeMethod('scanFile', {'path': newImage.path});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagen guardada en Galería')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permiso de fotos denegado')),
      );
    }
  }

void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Descargar imagen'),
                onTap: () async {
                  Navigator.pop(context);
                  await _downloadCurrentImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.visibility_off),
                title: Text('Ocultar interfaz'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _showUI = false;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playVideo(File videoFile) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(videoFile);
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    await _videoController!.play();
    setState(() {
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = widget.mediaList;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showUI = !_showUI;
          });
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: mediaList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isPlaying = false;
                  _videoController?.pause();
                });
              },
              itemBuilder: (context, index) {
                final media = mediaList[index];

                if (media.isVideo) {
                  if (_isPlaying && _currentIndex == index && _videoController != null && _videoController!.value.isInitialized) {
                    final videoSize = _videoController!.value.size;
                    final screenSize = MediaQuery.of(context).size;

                    final videoAspectRatio = videoSize.width / videoSize.height;
                    final screenAspectRatio = screenSize.width / screenSize.height;

                    double displayWidth;
                    double displayHeight;

                    if (videoAspectRatio > screenAspectRatio) {
                      // Video más ancho que pantalla
                      displayWidth = screenSize.width;
                      displayHeight = screenSize.width / videoAspectRatio;
                    } else {
                      // Video más alto o igual de proporcionado
                      displayHeight = screenSize.height;
                      displayWidth = screenSize.height * videoAspectRatio;
                    }

                    return Center(
                      child: SizedBox(
                        width: displayWidth,
                        height: displayHeight,
                        child: VideoPlayer(_videoController!),
                      ),
                    );
                  }else if (_isPlaying && _currentIndex != index) {
                    return Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.8), size: 50),
                    );

                  } else {
                    return FutureBuilder<File?>(
                      future: getVideoThumbnail(media.file),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              snapshot.data!,
                              fit: BoxFit.contain,
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () => _playVideo(media.file),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    );
                  }
                } else {
                  return Center(
                    child: Hero(
                      tag: media.file.path,
                      child: Image.file(
                        media.file,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }
              },
            ),
            if (_showUI) ...[
              Positioned(
                top: 40,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => _showOptionsMenu(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.more_vert, color: Colors.white, size: 24),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null && widget.title!.isNotEmpty)
                      Text(
                        widget.title!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black87, offset: Offset(1, 1))],
                        ),
                      ),
                    if (widget.phrase != null && widget.phrase!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.phrase!,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black87, offset: Offset(1, 1))],
                          ),
                        ),
                      ),
                  ],
                ),
              
              ),
            ]
          ],
        ),
      ),
    );
  }
}