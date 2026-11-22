import 'dart:async';
import 'dart:convert';

String fmtDur(Duration d) {
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours >= 1) {
    return '${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:$s';
  }
  return '${d.inMinutes}:$s';
}

String fmtTotal(int ms) {
  final m = (ms / 60000).round();
  return m >= 60 ? '${m ~/ 60} h ${m % 60} min' : '$m min';
}

String firstLetter(String t) {
  final s = t.trimLeft();
  if (s.isEmpty) return '#';
  final c = s[0].toUpperCase();
  return RegExp(r'[A-Z]').hasMatch(c) ? c : '#';
}

String encodeName(String n) => base64Url.encode(utf8.encode(n));
String decodeName(String s) =>
    utf8.decode(base64Url.decode(base64Url.normalize(s)));

class Debouncer {
  Debouncer(this.delay);
  final Duration delay;
  Timer? _t;
  void run(void Function() f) {
    _t?.cancel();
    _t = Timer(delay, f);
  }

  void dispose() => _t?.cancel();
}
