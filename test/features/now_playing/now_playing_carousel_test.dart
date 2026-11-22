import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metroplayer/features/now_playing/now_playing_carousel.dart';

Widget _carousel({
  required int currentIndex,
  required ValueChanged<int> onIndexChanged,
  required VoidCallback onTap,
  int itemCount = 3,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          height: 280,
          child: NowPlayingCarousel(
            currentIndex: currentIndex,
            itemCount: itemCount,
            artworkBuilder: (index) => ColoredBox(
              key: ValueKey('artwork-$index'),
              color: Colors.primaries[index],
            ),
            onIndexChanged: onIndexChanged,
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('swiping commits only the settled artwork', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _carousel(
        currentIndex: 0,
        onIndexChanged: selected.add,
        onTap: () {},
      ),
    );

    await tester.fling(
      find.byType(PageView),
      const Offset(-900, 0),
      2200,
    );
    await tester.pumpAndSettle();

    expect(selected, hasLength(1));
    expect(selected.single, inInclusiveRange(1, 2));
  });

  testWidgets('tapping a neighbor selects it and center opens lyrics',
      (tester) async {
    final selected = <int>[];
    var lyricsOpened = 0;

    await tester.pumpWidget(
      _carousel(
        currentIndex: 1,
        onIndexChanged: selected.add,
        onTap: () => lyricsOpened++,
      ),
    );
    final viewport = tester.getRect(find.byType(PageView));
    await tester.tapAt(Offset(viewport.left + 20, viewport.center.dy));
    expect(selected, [0]);

    await tester.pumpWidget(
      _carousel(
        currentIndex: 0,
        onIndexChanged: selected.add,
        onTap: () => lyricsOpened++,
      ),
    );
    await tester.pumpAndSettle();
    expect(selected, [0]);

    await tester.tap(find.byKey(const ValueKey('artwork-0')));
    expect(lyricsOpened, 1);
  });

  testWidgets('rapid external track changes settle without errors',
      (tester) async {
    const itemCount = 12;
    await tester.pumpWidget(
      _carousel(
        currentIndex: 0,
        itemCount: itemCount,
        onIndexChanged: (_) {},
        onTap: () {},
      ),
    );

    for (var index = 1; index < 9; index++) {
      await tester.pumpWidget(
        _carousel(
          currentIndex: index,
          itemCount: itemCount,
          onIndexChanged: (_) {},
          onTap: () {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 35));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
