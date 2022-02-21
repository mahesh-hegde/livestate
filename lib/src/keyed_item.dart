// I am going to use association list instead of hash maps!
// because you can expect, at a given time, that there are 2-3
// or maybe 4-5 callbacks on a given value. Not 100-200.

class KeyedItem<T> {
  KeyedItem(this.key, this.callback);
  int key;
  T callback;
}
