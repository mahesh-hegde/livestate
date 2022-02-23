import 'package:flutter/material.dart';

import 'live.dart';

class LiveWidget<T> extends StatefulWidget {
  const LiveWidget(Live<T> live, this.mapperFunc, {Key? key})
      : liveState = live,
        mapperFuncWithContext = null,
        super(key: key);
  const LiveWidget.withContext(
      this.liveState, Widget Function(BuildContext, T) mapperWithContext,
      {Key? key})
      : mapperFuncWithContext = mapperWithContext,
        mapperFunc = null,
        super(key: key);

  final Live<T> liveState;
  final Widget Function(T)? mapperFunc;
  final Widget Function(BuildContext, T)? mapperFuncWithContext;

  @override
  _LiveWidgetState<T> createState() => _LiveWidgetState<T>();
}

class _LiveWidgetState<T> extends State<LiveWidget<T>> {
  void setWidgetState(T _) {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    assert(widget.mapperFunc != null || widget.mapperFuncWithContext != null);
    super.initState();
    widget.liveState.addListener(setWidgetState);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapperFunc != null) {
      return widget.mapperFunc!(widget.liveState.value);
    } else {
      return widget.mapperFuncWithContext!(context, widget.liveState.value);
    }
  }

  @override
  void dispose() {
    widget.liveState.removeListenerCallback(setWidgetState);
    super.dispose();
  }
}

// Extension methods

extension WidgetCreation<T> on Live<T> {
  Widget widget(Widget Function(T) builder) => LiveWidget(this, builder);

  Widget widgetWithContext(Widget Function(BuildContext, T) builder) =>
      LiveWidget.withContext(this, builder);
}

// LiveWidget that listens to many LiveVariables

class MultiLiveWidget extends StatefulWidget {
	const MultiLiveWidget.withContext(this.list, this.builder, {Key? key}) : super(key: key);
	MultiLiveWidget(this.list, Widget Function() builder, {Key? key}) : builder = ((context) => builder()), super(key: key);
	final List<ChangePropagator> list;
	final Widget Function(BuildContext) builder;

	@override
	_MultiLiveWidgetState createState() => _MultiLiveWidgetState();
}

class _MultiLiveWidgetState extends State<MultiLiveWidget> {
	late List<int> listenerKeys;

	void setWidgetState() {
		setState(() {});
	}

	@override
	void initState() {
		super.initState();
		listenerKeys = widget.list.map((l) =>
			l.addNoArgListener(setWidgetState)).toList();
	}

	@override
	Widget build(BuildContext context) => widget.builder(context);

	@override
	void dispose() {
		for (int i = 0; i < listenerKeys.length; i++) {
			widget.list[i].removeNoArgListener(listenerKeys[i]);
		}
		super.dispose();
	}
}

