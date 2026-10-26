import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/album_art.dart';
import 'lyrics_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);
    final audioHandler = provider.audioHandler;
    return Scaffold(
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (ctx, snap) {
          final item = snap.data;
          if (item == null) {
            return const Center(child: Text('未在播放'));
          }
          final track =
              provider.tracks.where((t) => t.data == item.id).firstOrNull;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  provider.fluidColor,
                  provider.fluidColor.withValues(alpha: 0.65),
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    title: const Text('正在播放',
                        style: TextStyle(color: Colors.white)),
                    centerTitle: true,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AlbumArt(track: track, size: 280, radius: 24),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(item.artist ?? '',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 18),
                        StreamBuilder<Duration>(
                          stream: audioHandler.player.positionStream,
                          builder: (c, s) {
                            final pos = s.data ?? Duration.zero;
                            final dur = item.duration ?? Duration.zero;
                            final max = dur.inMilliseconds
                                .toDouble()
                                .clamp(1.0, 1073741824.0);
                            return Column(
                              children: [
                                Slider(
                                  value: pos.inMilliseconds
                                      .toDouble()
                                      .clamp(0.0, max),
                                  max: max,
                                  onChanged: (v) => audioHandler
                                      .seek(Duration(milliseconds: v.toInt())),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(pos),
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                    Text(_fmt(dur),
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous,
                                  color: Colors.white, size: 40),
                              onPressed: () => audioHandler.skipToPrevious(),
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
                                      color: Colors.white,
                                      size: 64),
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
                            IconButton(
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.white, size: 40),
                              onPressed: () => audioHandler.skipToNext(),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LyricsScreen())),
                          child: const Text('查看歌词',
                              style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
