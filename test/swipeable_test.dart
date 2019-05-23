import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipeable/swipeable.dart';

void main() {
  testWidgets('swipeable', (tester) async {
    await tester.pumpWidget(TestApp());
    expect(find.text('none'), findsOneWidget);
    await tester.drag(find.byType(Swipeable), Offset(500.0, 0));
    await tester.pumpAndSettle();
    expect(find.text('none'), findsNothing);
    expect(find.text('left'), findsNothing);
    expect(find.text('right'), findsOneWidget);
    await tester.drag(find.byType(Swipeable), Offset(-500.0, 0));
    await tester.pumpAndSettle();
    expect(find.text('none'), findsNothing);
    expect(find.text('right'), findsNothing);
    expect(find.text('left'), findsOneWidget);
  });
}

class TestApp extends StatefulWidget {
  _TestAppState createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  String _state;

  initState() {
    super.initState();
    _state = 'none';
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            width: 200,
            height: 200,
            child: Swipeable(
              background: Container(
                color: Colors.blue,
              ),
              child: Container(
                constraints: BoxConstraints.expand(),
                key: Key('foo'),
                child: Center(child: Text(_state)),
                color: Colors.white,
              ),
              onSwipeLeft: () => setState(() {
                    _state = "left";
                  }),
              onSwipeRight: () => setState(() {
                    _state = "right";
                  }),
            ),
          ),
        ),
      ),
    );
  }
}
