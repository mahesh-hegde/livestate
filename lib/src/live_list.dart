import 'keyed_item.dart';

typedef ListItemInsertListener<T> = void Function(int, T);
typedef ListItemRemoveListener<T> = void Function(int, T);
typedef ListItemChangeListener<T> = void Function(int, T, T);
typedef ListItemMoveListener<T> = void Function(int, int, T);
typedef ListRefreshListener<T> = void Function(List<T>);

/// List-like class which provides listeners on item change, remove, insert events.
/// A special move listener is also provided, because rearrangeable lists are very common.
class LiveList<T> extends Iterable<T> {
  List<T> _list;

  /// copying the elements of the iterable
  LiveList.ofElements(Iterable<T> elements) : _list = elements.toList();

  /// Create a LiveList which performs insert/remove/change operations
  /// on backingList.
  LiveList.backedBy(List<T> backingList) : _list = backingList;

  List<KeyedItem<ListItemChangeListener<T>>>? _changeListeners;
  List<KeyedItem<ListItemRemoveListener<T>>>? _removeListeners;
  List<KeyedItem<ListItemInsertListener<T>>>? _insertListeners;
  List<KeyedItem<ListItemMoveListener<T>>>? _moveListeners;
  List<KeyedItem<ListRefreshListener<T>>>? _refreshListeners;

  static List<KeyedItem<Q>> _adding<Q>(
      List<KeyedItem<Q>>? current, Q callback) {
    if (current == null) {
      return [KeyedItem(0, callback)];
    } else {
      // reason: since it's a (small) list
      // elements will be always in order
      current.add(KeyedItem(current.last.key + 1, callback));
      return current;
    }
  }

  static List<KeyedItem<Q>>? _removing<Q>(List<KeyedItem<Q>>? current, int i) {
    assert(current != null);
    assert(i < current!.length);
    if (current == null) return null;
    current.removeWhere((keyedCallback) => keyedCallback.key == i);
    // let the list be GC'd
    if (current.isEmpty) return null;
    return current;
  }

  /// Register a callback to be called on list index assignment (operator[]=)
  /// * Arguments to the callback shall be: (index, old value, new value).
  /// * The old value and new value will point to same object if the value
  /// is not reassigned, and modified in-place using .modifyAt() instead.
  /// * This function returns an integer key which can be used to unregister the callback.
  int addChangeListener(ListItemChangeListener<T> callback) {
    _changeListeners = _adding(_changeListeners, callback);
    return _changeListeners!.last.key;
  }

  /// Register a callback to be called when an item is removed;
  /// * Arguments to callback shall be (index, removedValue).
  /// * This function returns an integer key which can be used to unregister the callback.
  int addRemoveListener(ListItemRemoveListener<T> callback) {
    _removeListeners = _adding(_removeListeners, callback);
    return _removeListeners!.last.key;
  }

  /// Register a callback to be called when an item is inserted;
  /// * Arguments to callback shall be (index, insertedValue).
  /// * This function returns an integer key which can be used to unregister the callback.
  int addInsertListener(ListItemInsertListener<T> callback) {
    _insertListeners = _adding(_insertListeners, callback);
    return _insertListeners!.last.key;
  }

  /// Register a callback to be called after a move() operation;
  /// * Arguments shall be (value, oldIndex, newIndex);
  /// * By the time this callback is called, the value would have been moved to newIndex.
  /// * This function returns an integer key which can be used to unregister the callback.
  int addMoveListener(ListItemMoveListener<T> callback) {
    _moveListeners = _adding(_moveListeners, callback);
    return _moveListeners!.last.key;
  }

  /// Register a callback to be called after a modifyList operation, or setting backingList to other list.
  /// This is intended to be used for bulk manipulations on backing list itself, such as sorting.
  /// * Argument to this callback shall be the new backing list.
  /// * This function returns an integer key which can be used to unregister the callback.
  int addRefreshListener(ListRefreshListener<T> callback) {
    _refreshListeners = _adding(_refreshListeners, callback);
    return _refreshListeners!.last.key;
  }

  /// Unregister a change listener, provided a valid integer key
  void removeChangeListener(int key) {
    _changeListeners = _removing(_changeListeners, key);
  }

  /// Unregister a remove listener, provided a valid integer key
  void removeRemoveListener(int key) {
    _removeListeners = _removing(_removeListeners, key);
  }

  /// Unregister a insert listener, provided a valid integer key
  void removeInsertListener(int key) {
    _insertListeners = _removing(_insertListeners, key);
  }

  /// Unregister a move listener, provided a valid integer key
  void removeMoveListener(int key) {
    _moveListeners = _removing(_moveListeners, key);
  }

  /// Unregister a refresh listener, provided a valid integer key
  void removeRefreshListener(int key) {
    _refreshListeners = _removing(_refreshListeners, key);
  }

  /// Insert an element and notify appropriate listeners.
  void insert(int i, T t) {
    _list.insert(i, t);
    _insertListeners?.forEach((f) => f.callback(i, t));
  }

  /// Insert to end and notify appropriate listeners.
  void add(T t) => insert(_list.length, t);

  /// Remove element at position i, and notify appropriate listeners.
  /// Returns the removed element.
  T removeAt(int i) {
    var t = _list.removeAt(i);
    _removeListeners?.forEach((f) => f.callback(i, t));
    return t;
  }

  /// Remove first element equal to t.
  /// Returns false if the element does not exist, true otherwise.
  bool remove(T t) {
    var i = _list.indexOf(t);
    if (i == -1) return false;
    removeAt(i);
    return true;
  }

  /// Access the value at index i.
  /// Note that this method directly returns the value
  /// and not any type of reactive reference.
  T operator [](int i) {
    return _list[i];
  }

  /// Set the value at index i, and call all changeListeners.
  void operator []=(int i, T t) {
    var old = _list[i];
    _list[i] = t;
    for (var f in _changeListeners ?? const []) {
      f.callback(i, old, t);
    }
  }

  /// Modify the value in-place, and call changeListeners.
  /// The oldValue and newValue supplied to changeListener
  /// will be same, since objects are reference types.
  void modifyAt(int i, void Function(T) modifierFunc) {
    modifierFunc(_list[i]);
    _changeListeners?.forEach((f) => f.callback(i, _list[i], _list[i]));
  }

  /// Move element from oldIndex to newIndex.
  /// This overrides any action on individual insert and remove.
  void move(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final T item = _list.removeAt(oldIndex);
    _list.insert(newIndex, item);
    _moveListeners?.forEach((f) {
      f.callback(oldIndex, newIndex, item);
    });
  }

  // Modify the list in-place and call all refresh listeners
  void modifyList(void Function(List<T>) callback) {
    callback(_list);
    for (var f in _refreshListeners ?? const []) {
      f.callback(_list);
    }
  }

  // Replace backing list by new list and call all refresh listeners
  set backingList(List<T> newList) {
    _list = newList;
	_refreshListeners?.forEach((f) => f.callback(_list));
 }

  @override
  int get length => _list.length;

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  Iterator<T> get iterator => _list.iterator;

  /// returns the backing list of this LiveList.
  List<T> get backingList => _list;
}

