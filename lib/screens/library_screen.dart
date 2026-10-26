import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';
import '../widgets/track_tile.dart';
import 'now_playing_screen.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _section = 0;
  final TextEditingController _search = TextEditingController();

  List<Track> _base(PlayerProvider p) {
    switch (_section) {
      case 1:
        return p.favoritesList;
      case 2:
        return p.recentList;
      default:
        return p.tracks;
    }
  }

  List<Track> _filtered(PlayerProvider p) {
    final base = _base(p);
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q))
        .toList();
  }

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
    if (_section == 3) return _buildPlaylists(p);

    final list = _filtered(p);
    return Column(
      children: [
        const SizedBox(height: 8),
        _segmentBar(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜索歌曲、歌手、专辑',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('没有找到歌曲',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => TrackTile(
                    track: list[i],
                    onTap: () {
                      p.playFromList(list, i);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const NowPlayingScreen()));
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _segmentBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SegmentedButton<int>(
        selected: {_section},
        onSelectionChanged: (s) => setState(() => _section = s.first),
        segments: const [
          ButtonSegment(value: 0, label: Text('全部')),
          ButtonSegment(value: 1, label: Text('收藏')),
          ButtonSegment(value: 2, label: Text('最近')),
          ButtonSegment(value: 3, label: Text('歌单')),
        ],
      ),
    );
  }

  Widget _buildPlaylists(PlayerProvider p) {
    final names = p.playlistNames;
    return Column(
      children: [
        const SizedBox(height: 8),
        _segmentBar(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ...names.map((n) => ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(n),
                    subtitle: Text('${p.playlistTracks(n).length} 首'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => PlaylistDetailScreen(name: n)),
                    ),
                  )),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('新建歌单'),
                onTap: () async {
                  final name = await _askName(context);
                  if (name != null && name.trim().isNotEmpty) {
                    await p.createPlaylist(name.trim());
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String?> _askName(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('歌单名称'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入歌单名称'),
        ),
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
  }
}
