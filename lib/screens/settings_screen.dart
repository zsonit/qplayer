import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _shuffle = false;
  LoopMode _loop = LoopMode.off;

  @override
  Widget build(BuildContext context) {
    final audioHandler =
        Provider.of<PlayerProvider>(context, listen: false).audioHandler;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('QPlayer'),
          subtitle: Text('本地音乐播放器 · 流体歌词'),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('随机播放'),
          value: _shuffle,
          onChanged: (v) {
            setState(() => _shuffle = v);
            audioHandler.setShuffle(v);
          },
        ),
        const ListTile(title: Text('循环模式')),
        SegmentedButton<LoopMode>(
          selected: {_loop},
          onSelectionChanged: (s) {
            setState(() => _loop = s.first);
            audioHandler.setLoopMode(_loop);
          },
          segments: const [
            ButtonSegment(value: LoopMode.off, label: Text('关闭')),
            ButtonSegment(value: LoopMode.all, label: Text('列表循环')),
            ButtonSegment(value: LoopMode.one, label: Text('单曲循环')),
          ],
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.lyrics_outlined),
          title: Text('歌词说明'),
          subtitle: Text('将 .lrc 文件放在对应歌曲旁即可自动匹配'),
        ),
      ],
    );
  }
}
