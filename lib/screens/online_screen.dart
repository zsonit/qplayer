import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/online_provider.dart';
import '../services/online_models.dart';

class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key});

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> {
  final TextEditingController _c = TextEditingController();
  final FocusNode _fn = FocusNode();

  @override
  void dispose() {
    _c.dispose();
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final op = Provider.of<OnlineProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('在线音乐')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    focusNode: _fn,
                    onSubmitted: (v) => op.search(v),
                    decoration: InputDecoration(
                      hintText: '搜索歌曲 / 歌手',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => op.search(_c.text),
                  child: const Text('搜索'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (_) {
                if (op.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (op.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(op.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                if (op.results.isEmpty) {
                  return const Center(
                    child: Text('输入关键词搜索在线歌曲',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: op.results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = op.results[i];
                    return _OnlineTile(track: t, onTap: () => op.playTrack(t));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineTile extends StatelessWidget {
  final OnlineTrack track;
  final VoidCallback onTap;
  const _OnlineTile({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: track.coverUrl != null
            ? Image.network(
                track.coverUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [track.artist, track.album].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.play_circle_outline),
      onTap: onTap,
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.music_note, color: Colors.grey),
      );
}
