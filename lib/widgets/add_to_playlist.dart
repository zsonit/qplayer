import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/player_provider.dart';

void showAddToPlaylist(BuildContext context, Track track) {
  final p = Provider.of<PlayerProvider>(context, listen: false);
  final names = p.playlistNames;
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('添加到歌单',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...names.map((n) => ListTile(
                title: Text(n),
                onTap: () {
                  p.addToPlaylist(n, track);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已添加到「$n」')));
                },
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('新建歌单'),
            onTap: () async {
              Navigator.of(ctx).pop();
              final name = await _askName(context);
              if (name != null && name.trim().isNotEmpty) {
                await p.createPlaylist(name.trim());
                await p.addToPlaylist(name.trim(), track);
              }
            },
          ),
        ],
      ),
    ),
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
