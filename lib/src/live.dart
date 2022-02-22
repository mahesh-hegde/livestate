import 'keyed_item.dart';

import 'live_widget.dart';

import 'package:flutter/material.dart';

typedef Consumer<T> = void Function(T);

typedef Transformer<T> = T Function(T);

// Circus to be able to write
// Live.of([x, y, z], () => x.value + y.value + z.value)
abstract class _ChangeListenerNoArg {
  int addNoArgListener(void Function() callback);
}

class Live<T> extends _ChangeListenerNoArg {
  /// Constructor with an initial value
  Live(this._value);

  // Can't make constructors generic, thus static methods

  /// Create a Live<T> , which always updates
  /// when either ul or vl is updated.
  /// Make sure to supply type parameters explicitly.
  static Live<T> of2<U, V, T>(
      Live<U> ul, Live<V> vl, T Function(U, V) mapperFunc) {
    var ret = Live(mapperFunc(ul.value, vl.value));
    ul.addListener((u) => ret.value = mapperFunc(u, vl.value));
    vl.addListener((v) => ret.value = mapperFunc(ul.value, v));
    return ret;
  }

  /// Create a Live<T>, which always updates
  /// when any of ul, vl, wl is updated.
  /// Make sure to supply type parameters explicitly.
  static Live<T> of3<U, V, W, T>(
      Live<U> ul, Live<V> vl, Live<W> wl, T Function(U, V, W) mapperFunc) {
    var ret = Live(mapperFunc(ul.value, vl.value, wl.value));
    ul.addListener((u) => ret.value = mapperFunc(u, vl.value, wl.value));
    vl.addListener((v) => ret.value = mapperFunc(ul.value, v, wl.value));
    wl.addListener((w) => ret.value = mapperFunc(ul.value, vl.value, w));
    return ret;
  }

  /// Create a live variable that's recomputed when any Live in the list changes
  Live.ofAll(List<_ChangeListenerNoArg> list, T Function() generateFunc)
      : _value = generateFunc() {
    for (var l in list) {
      l.addNoArgListener(() => value = generateFunc());
    }
  }

  /// Add a listener which is called when any Live in list changes
  static void addListenerToAll(List<_ChangeListenerNoArg> list, void Function() listener) {
	for (var l in list) {
		l.addNoArgListener(listener);
	}
  }

  T _value;

  final List<KeyedItem<Consumer<T>>> _listeners = [];
  List<Live<T>>? _bound;

  /// Get the value held by Live variable
  T get value => _value;

  // parent parameter is passed
  // so that only one update happens in a bidirectional bind
  // you can still screw up by creating a cycle
  // That will lead to a stack overflow
  void _propagate({Live<T>? parent}) {
    for (var f in _listeners) {
      f.callback(_value);
    }
    var bound = _bound;
    if (bound != null) {
      for (var b in bound) {
        if (b == parent) continue;
        b._value = _value;
        b._propagate(parent: this);
      }
    }
  }

  /// set the value, call listeners if any, update bound variables if any.
  set value(T newVal) {
    _value = newVal;
    _propagate();
  }

  /// set the value to result of updateFunc(currentValue)
  void update(Transformer<T> updateFunc) {
    _value = updateFunc(_value);
    _propagate();
  }

  /// Modify the variable in-place and call listeners if any
  void modify(Consumer<T> modifyFunc) {
    modifyFunc(_value);
    _propagate();
  }

  /// Add a callback which will be executed any time the value is changed.
  /// Note that it's not executed on the current value;
  int addListener(Consumer<T> callback) {
    var key = _listeners.isEmpty ? 0 : _listeners.last.key + 1;
    _listeners.add(KeyedItem(key, callback));
    return key;
  }

  int addNoArgListener(void Function() callback) {
    return addListener((t) => callback());
  }

  /// Unregister the listener callback by equality comparison.
  /// The closure equality is well defined for static members & object methods,
  /// but not arbitrary closures.
  void removeListenerCallback(Consumer<T> callback) {
    int oldLen = 0;
    assert((oldLen = _listeners.length) != 0);
    _listeners
        .removeWhere((keyedCallback) => keyedCallback.callback == callback);
    assert(oldLen > _listeners.length);
  }

  // Unregister listener callback if the key is valid
  void removeListener(int key) {
    int oldLen = 0;
    assert((oldLen = _listeners.length) != 0);
    _listeners.removeWhere((keyedCallback) => keyedCallback.key == key);
    assert(oldLen > _listeners.length);
  }

  /// Create a Live variable mapping the current variable through a function.
  /// The value of derived live variable is updated whenever source is updated
  /// But not in reverse.
  Live<K> derive<K>(K Function(T) mapperFunc) {
    var ret = Live(mapperFunc(_value));
    addListener((t) => ret.value = mapperFunc(t));
    return ret;
  }

  void _attachWithoutSetting(Live<T> other) {
    if (_bound == null) {
      _bound = [other];
    } else {
      _bound?.add(other);
    }
  }

  /// Attach other Live variable such that
  /// whenever value of this variable is updated,
  /// value of that variable is also updated.
  void attach(Live<T> other) {
    other.value = _value;
    _attachWithoutSetting(other);
  }

  /// Detach the other variable.
  void detach(Live<T> other) {
    assert(_bound?.contains(other) ?? false);
    _bound?.remove(other);
  }

  /// Bidirectional binding between 2 variables
  void bind(Live<T> other) {
    attach(other);
    // don't call other.attach
    // because attach will set value using setter
    other._attachWithoutSetting(this);
  }

  /// Remove the bidirectional binding
  void unbind(Live<T> other) {
    assert(other._bound?.contains(this) ?? false);
    assert(_bound?.contains(other) ?? false);

    detach(other);
    other.detach(this);
  }

  /// clear any listeners
  void clearAllDependents() {
    _listeners.clear();
    _bound?.clear();
  }
}
