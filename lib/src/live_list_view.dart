import 'package:flutter/material.dart';

import 'live_list.dart';

/// A Material design ListView backed by a LiveList
/// The listViewBuilder doesn't need to return a ListView widget itself.
/// It can return a ReorderableListView, for example.
class LiveListView<T> extends StatefulWidget {
  const LiveListView(this.list, this.listViewBuilder, {Key? key})
      : super(key: key);
  final LiveList<T> list;
  final Widget Function(LiveList<T>) listViewBuilder;

  @override
  _LiveListViewState<T> createState() => _LiveListViewState();
}

class _LiveListViewState<T> extends State<LiveListView<T>> {
  late int _cpos, _rpos, _ipos, _mpos, _repos;
  @override
  void initState() {
    super.initState();
    var list = widget.list;
    _cpos = list.addChangeListener((pos, oldVal, newVal) => setState(() {}));
    _rpos = list.addRemoveListener((pos, val) => setState(() {}));
    _ipos = list.addInsertListener((pos, val) => setState(() {}));
    _mpos = list.addMoveListener((oldPos, newPos, val) => setState(() {}));
    _repos = list.addRefreshListener((list) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return widget.listViewBuilder(widget.list);
  }

  @override
  void dispose() {
    var list = widget.list;
    list.removeChangeListener(_cpos);
    list.removeRemoveListener(_rpos);
    list.removeInsertListener(_ipos);
    list.removeMoveListener(_mpos);
    list.removeRefreshListener(_repos);
    super.dispose();
  }
}

extension LiveListViewWidgetCreator<T> on LiveList<T> {
  Widget listView(Widget Function(LiveList<T>) builder) {
    return LiveListView(this, builder);
  }
}

typedef ListItemBuilder = Widget Function(BuildContext, int);

class LiveListView2<T> extends StatefulWidget {
  LiveListView2(
      {Key? key,
      required this.list,
      required Widget Function(BuildContext, T) itemBuilder,
      required this.listBuilder,
      bool reverse = false})
      : itemBuilder = ((context, i) => itemBuilder(
            context, reverse ? list[i] : list[list.length - i - 1]));
  LiveList<T> list;
  Widget Function(ListItemBuilder) listBuilder;
  ListItemBuilder itemBuilder;

  @override
  _LiveListView2State<T> createState() => _LiveListView2State<T>();
}

class _LiveListView2State<T> extends State<LiveListView2> {
  late int _cpos, _rpos, _ipos, _mpos, _repos;
  Map<int, VoidCallback> _stateSetters = {};
  @override
  void initState() {
    super.initState();
    var list = widget.list;
    _cpos = list.addChangeListener((pos, oldVal, newVal) => setState(() {}));
    _rpos = list.addRemoveListener((pos, val) => setState(() {}));
    _ipos = list.addInsertListener((pos, val) => setState(() {}));
    _mpos = list.addMoveListener((oldPos, newPos, val) => setState(() {}));
    _repos = list.addRefreshListener((list) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return widget.listBuilder(widget.itemBuilder);
  }

  @override
  void dispose() {
    var list = widget.list;
    list.removeChangeListener(_cpos);
    list.removeRemoveListener(_rpos);
    list.removeInsertListener(_ipos);
    list.removeMoveListener(_mpos);
    list.removeRefreshListener(_repos);
    super.dispose();
  }
}

class LiveListView2Item<T> extends StatefulWidget {
	LiveListView2Item(this.parentMap, this.index, this.widgetBuilder, this.list, {Key? key}): super(key: key);

	Map<int, VoidCallback> parentMap;
	int index; // index in list
	Widget Function(BuildContext, T) widgetBuilder;
	LiveList<T> list;

	@override
	_LiveListView2ItemState<T> createState() => _LiveListView2ItemState();
}

class _LiveListView2ItemState<T> extends State<LiveListView2Item> {
	void setWidgetState() {
		setState(() {});
	}

	@override
	void initState() {
		super.initState();
		widget.parentMap[widget.index] = setWidgetState;
	}

	@override
	Widget build(BuildContext context) {
		return widget.widgetBuilder(context, widget.list[widget.index]);
	}

	@override
	void dispose() {
		widget.parentMap.remove(widget.index);
		super.dispose();
	}
}

