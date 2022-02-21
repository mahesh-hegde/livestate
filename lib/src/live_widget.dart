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
    // Because any other way to prevent nullable variable in constructor
    // makes the constructor call require type params
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
