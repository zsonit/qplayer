import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/track_tile.dart';
import 'now_playing_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String name;
  const PlaylistDetailScreen({required this.name, super.key});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<PlayerProvider>(context);
    final tracks = p.playlistTracks(name);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _rename(context, p),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, p),
          ),
        ],
      ),
      body: tracks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '空歌单\n在「歌曲」页点 ⋮ 或长按可加入歌单',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (ctx, i) => TrackTile(
                track: tracks[i],
                showMenu: false,
                onTap: () {
                  p.playFromList(tracks, i);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const NowPlayingScreen()));
                },
                onLongPress: () {
                  p.removeFromPlaylist(name, tracks[i].data);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已从歌单移除')));
                },
              ),
            ),
    );
  }

  Future<void> _rename(BuildContext context, PlayerProvider p) async {
    final c = TextEditingController(text: name);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名歌单'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(c.text),
              child: const Text('确定')),
        ],
      ),
    );
    if (r != null && r.trim().isNotEmpty) {
      await p.renamePlaylist(name, r.trim());
    }
  }

  Future<void> _delete(BuildContext context, PlayerProvider p) async {
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定删除「$name」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await p.deletePlaylist(name);
      nav.pop();
    }
  }
}
