import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../services/library_service.dart';
import '../services/player_handler.dart';
import '../utils/lrc_parser.dart';

class PlayerProvider extends ChangeNotifier {
  final QPlayerHandler audioHandler;
  final LibraryService _library = LibraryService();

  final List<Track> _tracks = [];
  List<Track> get tracks => _tracks;

  List<LrcLine> _lyrics = [];
  List<LrcLine> get lyrics => _lyrics;

  Color _fluidColor = const Color(0xFF1C1C1E);
  Color get fluidColor => _fluidColor;

  bool _loading = false;
  bool get loading => _loading;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  String _onlineProxyUrl = '';
  String get onlineProxyUrl => _onlineProxyUrl;

  final Set<String> _favorites = {};
  final List<String> _recent = [];
  final Map<String, List<String>> _playlists = {};

  PlayerProvider(this.audioHandler) {
    audioHandler.mediaItem.listen((item) {
      if (item == null) return;
      if (item.extras?['online'] == true) {
        final lrc = item.extras?['lyric'];
        _lyrics = (lrc is String && lrc.isNotEmpty) ? parseLrc(lrc) : [];
        _loadFluidColorFromUri(item.artUri);
        notifyListeners();
      } else {
        final t = _trackByPath(item.id);
        if (t != null) _refreshForTrack(t);
      }
    });
  }

  Future<void> loadLibrary() async {
    _loading = true;
    notifyListeners();
    await _loadPrefs();
    _hasPermission = await _library.requestPermission();
    if (_hasPermission) {
      _tracks.clear();
      _tracks.addAll(await _library.loadSongs());
    }
    _loading = false;
    notifyListeners();
  }

  // ---- persistence ----
  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites.addAll(prefs.getStringList('qp_fav') ?? []);
      _recent.addAll(prefs.getStringList('qp_recent') ?? []);
      final pl = prefs.getString('qp_playlists');
      if (pl != null) {
        final map = json.decode(pl) as Map<String, dynamic>;
        map.forEach((k, v) => _playlists[k] = List<String>.from(v as List));
      }
      _onlineProxyUrl = prefs.getString('qp_online_proxy') ?? '';
    } catch (_) {}
  }

  Future<void> _saveFav() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('qp_fav', _favorites.toList());
    } catch (_) {}
  }

  Future<void> _saveRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('qp_recent', _recent);
    } catch (_) {}
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('qp_playlists', json.encode(_playlists));
    } catch (_) {}
  }

  // ---- favorites ----
  bool isFavorite(String path) => _favorites.contains(path);

  void toggleFavorite(Track t) {
    if (_favorites.contains(t.data)) {
      _favorites.remove(t.data);
    } else {
      _favorites.add(t.data);
    }
    _saveFav();
    notifyListeners();
  }

  List<Track> get favoritesList => _resolve(_favorites.toList());

  // ---- recent ----
  void addRecent(Track t) {
    _recent.remove(t.data);
    _recent.insert(0, t.data);
    if (_recent.length > 100) _recent.removeRange(100, _recent.length);
    _saveRecent();
    notifyListeners();
  }

  List<Track> get recentList => _resolve(_recent);

  List<String> get recent => _recent;

  Future<void> clearRecent() async {
    _recent.clear();
    await _saveRecent();
    notifyListeners();
  }

  // ---- playlists ----
  List<String> get playlistNames => _playlists.keys.toList()..sort();

  List<Track> playlistTracks(String name) =>
      _resolve(_playlists[name] ?? const []);

  Future<void> createPlaylist(String name) async {
    final n = name.trim();
    if (n.isEmpty || _playlists.containsKey(n)) return;
    _playlists[n] = [];
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String oldName, String newName) async {
    final n = newName.trim();
    if (n.isEmpty || oldName == n || _playlists.containsKey(n)) return;
    final list = _playlists.remove(oldName) ?? [];
    _playlists[n] = list;
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String name) async {
    _playlists.remove(name);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addToPlaylist(String name, Track t) async {
    if (!_playlists.containsKey(name) || _playlists[name]!.contains(t.data)) {
      return;
    }
    _playlists[name]!.add(t.data);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> removeFromPlaylist(String name, String path) async {
    if (!_playlists.containsKey(name)) return;
    _playlists[name]!.remove(path);
    await _savePlaylists();
    notifyListeners();
  }

  // ---- helpers ----
  List<Track> _resolve(List<String> paths) {
    final out = <Track>[];
    for (final p in paths) {
      final t = _trackByPath(p);
      if (t != null) out.add(t);
    }
    return out;
  }

  Track? _trackByPath(String path) {
    for (final t in _tracks) {
      if (t.data == path) return t;
    }
    return null;
  }

  Future<void> playFromList(List<Track> list, int startIndex) async {
    if (list.isEmpty) return;
    startIndex = startIndex.clamp(0, list.length - 1);
    final items = list.map((t) => MediaItem(
          id: t.data,
          title: t.title,
          artist: t.artist,
          album: t.album,
          duration: Duration(milliseconds: t.durationMs),
        )).toList();
    final uris = list.map((t) => t.data).toList();
    await audioHandler.setQueue(items, uris);
    await audioHandler.jumpToIndex(startIndex);
    _refreshForTrack(list[startIndex]);
    addRecent(list[startIndex]);
  }

  Future<void> _refreshForTrack(Track t) async {
    _loadLyrics(t);
    _loadFluidColor(t);
  }

  Future<void> _loadLyrics(Track t) async {
    final path = _library.findLrcPath(t.data);
    if (path != null) {
      try {
        final content = await File(path).readAsString();
        _lyrics = parseLrc(content);
      } catch (_) {
        _lyrics = [];
      }
    } else {
      _lyrics = [];
    }
    notifyListeners();
  }

  Future<void> _loadFluidColor(Track t) async {
    Uint8List? bytes;
    if (t.albumId != 0) {
      bytes = await _library.artwork(t.albumId, ArtworkType.ALBUM, size: 200);
    }
    if (bytes == null && t.id != 0) {
      bytes = await _library.artwork(t.id, ArtworkType.AUDIO, size: 200);
    }
    Color color = const Color(0xFF1C1C1E);
    if (bytes != null) {
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(bytes),
          size: const Size(200, 200),
        );
        color = palette.dominantColor?.color ?? color;
      } catch (_) {
        color = const Color(0xFF1C1C1E);
      }
    }
    _fluidColor = color;
    notifyListeners();
  }

  Future<void> _loadFluidColorFromUri(Uri? uri) async {
    if (uri == null) {
      _fluidColor = const Color(0xFF1C1C1E);
      notifyListeners();
      return;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(uri.toString()),
        size: const Size(200, 200),
      );
      _fluidColor = palette.dominantColor?.color ?? const Color(0xFF1C1C1E);
    } catch (_) {
      _fluidColor = const Color(0xFF1C1C1E);
    }
    notifyListeners();
  }

  // ---- online proxy / online lyric ----
  Future<void> setOnlineProxy(String v) async {
    _onlineProxyUrl = v.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('qp_online_proxy', _onlineProxyUrl);
    } catch (_) {}
    notifyListeners();
  }

  void setOnlineLyric(String lrc) {
    _lyrics = lrc.isNotEmpty ? parseLrc(lrc) : [];
    notifyListeners();
  }
}
