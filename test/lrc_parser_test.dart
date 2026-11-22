import 'package:flutter_test/flutter_test.dart';
import 'package:metroplayer/domain/lrc.dart';

void main() {
  test('parses timestamps, multiple stamps and offset', () {
    final lines = LrcParser.parse(
      '[offset:500]\n'
      '[00:01.00][00:03.50]hello\n'
      '[00:02.5]world\n'
      '[ar:someone]\n'
      'not a lyric\n',
    );
    expect(lines.length, 3);
    expect(lines[0].time, const Duration(milliseconds: 500));
    expect(lines[0].text, 'hello');
    expect(lines[1].time, const Duration(milliseconds: 2000));
    expect(lines[1].text, 'world');
    expect(lines[2].time, const Duration(milliseconds: 3000));
  });

  test('handles empty input', () {
    expect(LrcParser.parse(''), isEmpty);
  });

  test('removes version labels and time tags from displayed lyrics', () {
    const source =
        'v1:\n[00:01.00]first line\n[00:02.00]second line\n[ar:artist]';

    expect(
      LrcParser.parse(source).map((line) => line.text),
      ['first line', 'second line'],
    );
    expect(LrcParser.plainText(source), 'first line\nsecond line');
  });

  test('strips inline angle-bracket timestamps from versioned lyrics', () {
    const source =
        '[03:50.625]v1:<03:50.625>Thirty <03:50.941><03:50.941>years <03:51.000>';

    expect(LrcParser.parse(source).single.text, 'Thirty years');
    expect(LrcParser.plainText(source), 'Thirty years');
  });
}
