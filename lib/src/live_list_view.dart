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


