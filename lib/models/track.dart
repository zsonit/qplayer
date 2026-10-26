class Track {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final int durationMs;
  final String data;
  final String displayName;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.durationMs,
    required this.data,
    required this.displayName,
  });

  factory Track.fromSong(dynamic song) {
    return Track(
      id: (song.id as int?) ?? 0,
      title: (song.title as String?)?.trim().isNotEmpty == true
          ? (song.title as String)
          : 'Unknown',
      artist: (song.artist as String?)?.trim().isNotEmpty == true
          ? (song.artist as String)
          : 'Unknown Artist',
      album: (song.album as String?)?.trim().isNotEmpty == true
          ? (song.album as String)
          : 'Unknown Album',
      albumId: (song.albumId as int?) ?? 0,
      durationMs: (song.duration as int?) ?? 0,
      data: (song.data as String?) ?? '',
      displayName: (song.displayName as String?) ?? '',
    );
  }

  /// Stable identity key (absolute file path).
  String get key => data;

  @override
  bool operator ==(Object other) => other is Track && other.data == data;

  @override
  int get hashCode => data.hashCode;
}
