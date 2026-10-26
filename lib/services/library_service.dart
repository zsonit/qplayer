import 'dart:io';
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/track.dart';

class LibraryService {
  final OnAudioQuery _query = OnAudioQuery();

  /// Requests media-library permission. Works on Android (READ_MEDIA_AUDIO /
  /// READ_EXTERNAL_STORAGE) and iOS (media library).
  Future<bool> requestPermission() async {
    bool granted = false;
    try {
      granted = await _query.permissionsStatus();
    } catch (_) {
      granted = false;
    }
    if (!granted) {
      try {
        granted = await _query.permissionsRequest();
      } catch (_) {
        granted = false;
      }
    }
    return granted;
  }

  Future<List<Track>> loadSongs() async {
    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return songs.map((s) => Track.fromSong(s)).toList();
  }

  Future<Uint8List?> artwork(int id, ArtworkType type, {int size = 300}) async {
    try {
      return await _query.queryArtwork(
        id,
        type,
        size: size,
        format: ArtworkFormat.JPEG,
      );
    } catch (_) {
      return null;
    }
  }

  /// Looks for a sidecar .lrc next to the audio file (same name, various
  /// extensions). Returns the path or null.
  String? findLrcPath(String data) {
    if (data.isEmpty) return null;
    final file = File(data);
    final dir = file.parent.path;
    final name = file.uri.pathSegments.last;
    final noExt = name.replaceAll(RegExp(r'\.[^.]+$'), '');
    const candidates = ['.lrc', '.LRC', '_lyric.lrc', '_lyric.LRC'];
    for (final ext in candidates) {
      final p = '$dir/$noExt$ext';
      if (File(p).existsSync()) return p;
    }
    return null;
  }
}
