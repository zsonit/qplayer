class LrcLine {
  final Duration time;
  final String text;
  LrcLine(this.time, this.text);
}

List<LrcLine> parseLrc(String content) {
  final lines = <LrcLine>[];
  // Match one or more [mm:ss.xx] tags at the start of a line.
  final tag = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
  for (final raw in content.split('\n')) {
    final matches = tag.allMatches(raw);
    if (matches.isEmpty) continue;
    final text = raw.replaceAll(tag, '').trim();
    if (text.isEmpty) continue;
    for (final m in matches) {
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final frac = m.group(3) ?? '0';
      final msStr = frac.length >= 3 ? frac.substring(0, 3) : frac.padRight(3, '0');
      final ms = int.parse(msStr);
      lines.add(LrcLine(Duration(minutes: min, seconds: sec, milliseconds: ms), text));
    }
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}

/// Returns the index of the lyric line that should be highlighted at [pos].
int activeLrcIndex(List<LrcLine> lines, Duration pos) {
  int idx = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].time <= pos) {
      idx = i;
    } else {
      break;
    }
  }
  return idx;
}
