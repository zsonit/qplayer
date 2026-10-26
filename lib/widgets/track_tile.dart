import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';
import 'album_art.dart';
import 'add_to_playlist.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final bool showMenu;
  final VoidCallback? onLongPress;
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.showMenu = true,
    this.onLongPress,
  });

  String _fmt(int ms) {
    final s = (ms ~/ 1000);
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<PlayerProvider>(context);
    final fav = p.isFavorite(track.data);
    return ListTile(
      leading: AlbumArt(track: track, size: 52, radius: 10),
      title: Text(track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(track.artist,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMenu)
            IconButton(
              icon: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: fav ? Colors.red : Colors.grey,
              ),
              onPressed: () => p.toggleFavorite(track),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (showMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (v) {
                if (v == 'pl') showAddToPlaylist(context, track);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'pl', child: Text('添加到歌单')),
              ],
            ),
          Text(_fmt(track.durationMs),
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
