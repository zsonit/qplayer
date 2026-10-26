import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../services/online_models.dart';
import '../services/online_source.dart';
import '../services/netease_source.dart';
import '../services/player_handler.dart';
import '../providers/player_provider.dart';

/// 统一管理在线音源：搜索、试听/播放、歌词。
///
/// 当前内置网易云音源（直连 + 代理双模式）。后续接入更多音源时，
/// 在 [sources] 中追加实现 [OnlineSource] 的类即可。
class OnlineProvider extends ChangeNotifier {
  final QPlayerHandler audioHandler;
  final PlayerProvider player;

  List<OnlineTrack> results = [];
  bool loading = false;
  String? error;

  OnlineProvider(this.audioHandler, this.player);

  /// 当前可用音源列表（预留多音源扩展）。
  List<OnlineSource> get sources => [NeteaseSource(player.onlineProxyUrl)];

  OnlineSource get _source => sources.first;

  Future<void> search(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) {
      results = [];
      error = null;
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      results = await _source.search(kw);
      if (results.isEmpty) error = '没有找到相关歌曲';
    } catch (e) {
      error = e.toString();
      results = [];
    }
    loading = false;
    notifyListeners();
  }

  /// 播放单首在线歌曲：取可播放地址 + 歌词，交给现有 just_audio 播放链路。
  Future<void> playTrack(OnlineTrack t) async {
    try {
      final url = await _source.songUrl(t.id);
      if (url == null || url.isEmpty) {
        error = '该歌曲暂无可用音源（可能需要登录或 VIP）';
        notifyListeners();
        return;
      }
      final lyric = await _source.lyric(t.id);
      final item = MediaItem(
        id: url,
        title: t.title,
        artist: t.artist,
        album: t.album,
        duration: Duration(milliseconds: t.durationMs),
        artUri: t.coverUrl != null ? Uri.tryParse(t.coverUrl!) : null,
        extras: {
          'online': true,
          'onlineId': t.id,
          'lyric': lyric ?? '',
        },
      );
      await audioHandler.setQueue([item], [url]);
      await audioHandler.jumpToIndex(0);
      // 直接注入歌词，确保「歌词」页立即显示。
      player.setOnlineLyric(lyric ?? '');
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
