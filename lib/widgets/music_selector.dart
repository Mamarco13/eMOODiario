import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicSelector extends StatelessWidget {
  final List<String> tracks;
  final String? selectedTrack;
  final bool isGenerating;
  final AudioPlayer? audioPlayer;
  final Function(String?) onSelected;

  const MusicSelector({
    Key? key,
    required this.tracks,
    required this.selectedTrack,
    required this.isGenerating,
    required this.audioPlayer,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tracks.map((trackPath) {
        final name = trackPath.split('/').last.replaceAll('.mp3', '');
        return Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Radio<String>(
                value: trackPath,
                groupValue: selectedTrack,
                onChanged: isGenerating ? null : onSelected,
              ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: isGenerating ? null : () async {
                  audioPlayer?.stop();
                  await audioPlayer?.play(
                    AssetSource(trackPath.replaceFirst('assets/', '')),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.stop),
                onPressed: isGenerating ? null : () async {
                  await audioPlayer?.stop();
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
