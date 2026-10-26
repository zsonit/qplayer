/// 在线音源返回的歌曲模型（与本地 Track 解耦）。
class OnlineTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? coverUrl;
  final int durationMs;

  const OnlineTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.coverUrl,
    this.durationMs = 0,
  });

  /// 解析网易云搜索结果中的单首歌曲 JSON。
  factory OnlineTrack.fromNetease(Map<String, dynamic> j) {
    final artists = (j['artists'] as List? ?? [])
        .map((a) => a['name'])
        .where((n) => n != null)
        .join(' / ');
    final album = (j['album'] is Map) ? (j['album']['name'] ?? '') : '';
    final cover = (j['album'] is Map) ? j['album']['picUrl'] : null;
    final dt = j['dt'] ?? j['duration'] ?? 0;
    return OnlineTrack(
      id: j['id'].toString(),
      title: j['name'] ?? '',
      artist: artists,
      album: album,
      coverUrl: cover,
      durationMs: dt is int ? dt : (dt as num).toInt(),
    );
  }
}
