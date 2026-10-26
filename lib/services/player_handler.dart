import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QPlayerHandler extends BaseAudioHandler {
  final AudioPlayer player = AudioPlayer();
  List<MediaItem> _queue = [];
  List<String> _uris = [];

  QPlayerHandler() {
    _init();
  }

  void _init() {
    player.playbackEventStream.listen((event) {
      final playing = player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        playing: playing,
        processingState: _toProcessingState(player.processingState),
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
      ));
    });

    player.currentIndexStream.listen((idx) {
      if (idx != null && idx >= 0 && idx < _queue.length) {
        mediaItem.add(_queue[idx]);
      }
    });
  }

  AudioProcessingState _toProcessingState(ProcessingState s) {
    switch (s) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Builds the playlist from [items]/[uris] and publishes the queue.
  Future<void> setQueue(List<MediaItem> items, List<String> uris) async {
    _queue = items;
    _uris = uris;
    final sources =
        uris.map((u) => AudioSource.uri(Uri.parse(u))).toList();
    await player.setAudioSources(sources, preload: true);
    queue.add(items);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  Future<void> setLoopMode(LoopMode mode) => player.setLoopMode(mode);

  Future<void> setShuffle(bool enabled) =>
      player.setShuffleModeEnabled(enabled);

  Future<void> jumpToIndex(int index) async {
    if (index < 0 || index >= _uris.length) return;
    await player.seek(Duration.zero, index: index);
    await player.play();
  }
}
