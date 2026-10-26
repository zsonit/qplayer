import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
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

  PlayerProvider(this.audioHandler) {
    audioHandler.player.currentIndexStream.listen((idx) {
      if (idx != null && idx >= 0 && idx < _tracks.length) {
        _refreshForTrack(_tracks[idx]);
      }
    });
  }

  Future<void> loadLibrary() async {
    _loading = true;
    notifyListeners();
    _hasPermission = await _library.requestPermission();
    if (_hasPermission) {
      _tracks.clear();
      _tracks.addAll(await _library.loadSongs());
    }
    _loading = false;
    notifyListeners();
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
}
