import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../providers/player_provider.dart';
import '../services/player_handler.dart';
import 'album_art.dart';

class MiniPlayer extends StatelessWidget {
  final QPlayerHandler audioHandler;
  final VoidCallback onOpen;
  const MiniPlayer(
      {super.key, required this.audioHandler, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final provider =
        provider_pkg.Provider.of<PlayerProvider>(context, listen: false);
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (ctx, snap) {
        final item = snap.data;
        if (item == null) return const SizedBox.shrink();
        final realTrack =
            provider.tracks.where((t) => t.data == item.id).firstOrNull;
        return GestureDetector(
          onTap: onOpen,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                AlbumArt(track: realTrack, size: 44, radius: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(item.artist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (c, s) {
                    final playing = s.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(
                          playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 36,
                          color: Colors.blue),
                      onPressed: () {
                        if (playing) {
                          audioHandler.pause();
                        } else {
                          audioHandler.play();
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
