import 'online_models.dart';

/// 可插拔在线音源接口。
///
/// 任何在线音乐服务（网易云、QQ 音乐、自建代理等）实现该接口即可被
/// [OnlineProvider] 统一管理。后续接入新音源只需新增一个实现类。
abstract class OnlineSource {
  /// 唯一标识，如 'netease'。
  String get id;

  /// 展示名，如 '网易云音乐'。
  String get name;

  /// 搜索歌曲，返回候选列表。
  Future<List<OnlineTrack>> search(String keyword, {int limit = 30});

  /// 获取某首歌的可播放音频地址（HTTP/HTTPS URL）。
  Future<String?> songUrl(String id);

  /// 获取某首歌的 LRC 歌词原文（可能含 [mm:ss.xx] 时间标签）。
  Future<String?> lyric(String id);
}
