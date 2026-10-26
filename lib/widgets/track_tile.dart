import 'package:flutter/material.dart';
import '../models/track.dart';
import 'album_art.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  const TrackTile({super.key, required this.track, required this.onTap});

  String _fmt(int ms) {
    final s = (ms ~/ 1000);
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AlbumArt(track: track, size: 52, radius: 10),
      title: Text(track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(track.artist,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(_fmt(track.durationMs),
          style: const TextStyle(color: Colors.grey)),
      onTap: onTap,
    );
  }
}
