import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/track.dart';
import '../services/library_service.dart';

class AlbumArt extends StatelessWidget {
  final Track? track;
  final double size;
  final double radius;
  const AlbumArt({super.key, this.track, this.size = 56, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    if (track == null || (track!.albumId == 0 && track!.id == 0)) {
      return _placeholder();
    }
    final id = track!.albumId != 0 ? track!.albumId : track!.id;
    final type = track!.albumId != 0 ? ArtworkType.ALBUM : ArtworkType.AUDIO;
    final svc = LibraryService();
    return FutureBuilder<Uint8List?>(
      future: svc.artwork(id, type, size: size.toInt() * 2),
      builder: (ctx, snap) {
        if (snap.hasData && snap.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(
              snap.data as Uint8List,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Color(0xFF8E8E93), Color(0xFF48484A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.music_note, color: Colors.white70, size: size * 0.5),
    );
  }
}
