import 'package:flutter_test/flutter_test.dart';

import 'package:livestate/livestate.dart';

void main() {
  test('Test update and map', () {
	var x = Live(0);
	var xstr = x.derive((i) => "$i;");
	expect(xstr.value, "0;");
	x.value = 1;
	expect(xstr.value, "1;");
	x.setValueWithoutNotifyingListeners(5);
	expect(xstr.value, "1;");
  });

  test('Test LiveState derived from 2 states', (){
	var x = Live(0);
	var y = Live(1);
	var sum = Live.of2<int, int, int>(x, y, (x, y) => x+y);
	expect(sum.value, 1);
	x.value = 1;
	expect(sum.value, 2);
	y.value = 0;
	expect(sum.value, 1);
	x.value = 2; y.value = 2;
	expect(sum.value, 4);
  });

  test('Test attach', () {
	var x = Live(0);
	var y = Live(1);
	x.attach(y);
	x.value = 10;
	expect(x.value, 10);
	expect(y.value, 10);
	x.detach(y);
	x.value = 12;
	expect(x.value, 12);
	expect(y.value, 10);
  });

  test('Test bind', (){
	var x = Live(0);
	var y = Live(1);
	x.bind(y);
	expect(y.value, 0);
	x.value = 1;
	expect(y.value, 1);
	y.value = 2;
	expect(x.value, 2);
	x.unbind(y);
	x.value = 1;
	expect(y.value, 2);
	y.value = 4;
	expect(x.value, 1);
  });

  test('test Live.of', () {
	var x = Live(0);
	var y = Live("String");
	var z = Live(5);
	var xyz = Live.ofAll([x,y,z], () => "${x.value}, ${y.value}, ${z.value}");
	expect(xyz.value, "0, String, 5");
	z.value = 6;
	expect(xyz.value, "0, String, 6");
  });

  test('Test multiple listeners', () {
	var x = Live(0);
	var i = 0;
	x.addListener((value) => i = value);
	var y = x.derive((xv) => xv*2);
	var z = Live(0);
	x.attach(z);
	var zz = Live(0);
	x.bind(zz);

	testvals(int xval) {
		expect(i, xval);
		expect(y.value, xval*2);
		expect(z.value, xval);
		expect(zz.value, xval);
	}
	x.value = 6;
	testvals(6);
	zz.value = 8;
	expect(x.value, 8);
	testvals(8);
  });

  test('Test LiveList basics', () {
	testLiveListBasics(LiveList.ofElements([1, 4, 17, 6, 11]));
	testLiveListBasics(LiveList.backedBy([65, 11, 100, 45, 10, 16, 96]));
  });
}

void testLiveListBasics(LiveList<int> list) {
	assert(list.isNotEmpty);
	var sum = 0;
	for (var num in list) { sum += num; }
	var initialSum = sum;
	list.addChangeListener((i, o, n) => sum = sum - o + n);
	list.addRemoveListener((i, v) => sum -= v);
	list.addInsertListener((i, v) => sum += v);
	list.add(5);
	expect(sum, initialSum + 5);
	list.insert(0, 10);
	expect(sum, initialSum + 15);
	var rem = list.removeAt(1);
	expect(sum, initialSum + 15 - rem);
	list.remove(5);
	expect(sum, initialSum + 10 - rem);
	var o = list[0];
	var esum = initialSum + 10 - rem - o + 100;
	list[0] = 100;
	expect(sum, esum);
}
