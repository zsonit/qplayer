import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_tile.dart';
import 'now_playing_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<PlayerProvider>(context);
    if (p.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!p.hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('需要访问媒体库权限', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => p.loadLibrary(),
              child: const Text('重新请求权限'),
            ),
          ],
        ),
      );
    }
    if (p.tracks.isEmpty) {
      return const Center(
          child: Text('没有找到本地音乐', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: p.tracks.length,
      itemBuilder: (ctx, i) => TrackTile(
        track: p.tracks[i],
        onTap: () {
          p.playFromList(p.tracks, i);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const NowPlayingScreen()));
        },
      ),
    );
  }
}
