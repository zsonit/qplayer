import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../utils/lrc_parser.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ScrollController _scroll = ScrollController();
  int _lastIdx = -1;

  void _scrollTo(int idx, int total) {
    if (idx == _lastIdx || !_scroll.hasClients) return;
    _lastIdx = idx;
    final itemH = 56.0;
    final target = (idx * itemH) - (MediaQuery.of(context).size.height / 2) + itemH / 2;
    _scroll.animateTo(
      target.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayerProvider>(context);
    final audioHandler = provider.audioHandler;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              provider.fluidColor,
              provider.fluidColor.withValues(alpha: 0.6),
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
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: const Text('歌词',
                    style: TextStyle(color: Colors.white)),
                centerTitle: true,
              ),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: audioHandler.player.positionStream,
                  builder: (c, s) {
                    final pos = s.data ?? Duration.zero;
                    final lines = provider.lyrics;
                    if (lines.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '暂无歌词\n将 .lrc 文件放在歌曲旁边即可显示歌词',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ),
                      );
                    }
                    final idx = activeLrcIndex(lines, pos);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollTo(idx, lines.length);
                    });
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(vertical: 120),
                      itemCount: lines.length,
                      itemBuilder: (ctx, i) {
                        final active = i == idx;
                        return Container(
                          height: 56,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            lines[i].text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: active ? 22 : 17,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
