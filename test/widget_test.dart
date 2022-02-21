import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livestate/livestate.dart';

import 'dart:math';

void main() {
  testWidgets('Test LiveWidget and Live.update', (tester) async {
    var counter = Live(0);
    var derived =
        Live.of2<int, int, int>(counter, counter, (x, y) => max(x, y));
    await tester.pumpWidget(
        MaterialAppWrapper(derived.widget((count) => Text("<$count>"))));
    expect(find.text("<0>"), findsOneWidget);
    counter.value++;
    await tester.pumpAndSettle();
    expect(find.text("<0>"), findsNothing);
    expect(find.text("<1>"), findsOneWidget);
  });

  testWidgets('test LiveListView and LiveList listeners', (tester) async {
    var xs = ["A", "B", "C", "D", "E", "F"];
    var xsl = LiveList.backedBy(xs);
    await tester.pumpWidget(
        MaterialAppWrapper(xsl.listView((xsl) => ReorderableListView.builder(
			  key: const Key("ListView"),
              itemCount: xsl.length,
              itemBuilder: (context, i) => ListTile(
				key: Key(xsl[i]),
                title: Text(xsl[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => xsl.removeAt(i),
                ),
              ),
              onReorder: xsl.move,
            ))));
	
	verifyList(List<String> list) async {
		await tester.pumpAndSettle();
		// This part is useless
		// Because all our test items will be in viewport
		// But it passes
		for (var s in list) {
			var itemFinder = find.byKey(ValueKey(s));
			await tester.scrollUntilVisible(
				itemFinder,
				500.0,
			);
			expect(itemFinder, findsOneWidget);
		}
		expect(xsl.length, list.length);
		for (int i = 0; i < xsl.length; i++) {
			expect(xsl[i], list[i]);
		}
	}

	xsl.removeAt(0);
	await verifyList(["B", "C", "D", "E", "F"]);
	xsl.remove("E");
	await verifyList(["B", "C", "D", "F"]);
	xsl.move(0, 2);
	await verifyList(["C", "B", "D", "F"]);
	xsl.move(3, 0);
	await verifyList(["F", "C", "B", "D"]);
	xsl.insert(0, "A");
	await verifyList(["A", "F", "C", "B", "D"]);
	xsl.modifyList((list) => list.sort());
	await verifyList(["A", "B", "C", "D", "F"]);
	xsl.backingList = ["0", "1", "2"];
	await verifyList(["0", "1", "2"]);
  });
}

class MaterialAppWrapper extends StatelessWidget {
  const MaterialAppWrapper(this.child, {Key? key}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LiveState Test",
      home: Scaffold(
        appBar: AppBar(
          title: const Text("LiveState Test"),
        ),
        body: Center(child: child),
      ),
    );
  }
}
