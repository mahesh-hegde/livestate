## LiveState
This package is a simple generic implementation of observable values and lists for __flutter__, written for learning purpose.

## Usage
### Type Live<T>: Observable object

The fundamental observable type is `Live<T>`. 

* Create a Live variable by supplying an initial value.
```dart
var counter = Live(0);
```

* Create a widget that automatically updates with the variable, using the `widget` method.
```dart
var countTextWidget = counter.widget((count) => Text("$"))
```

* Update the live variable in a function, eg: event handler;
```dart
IconButton(
	icon: Icon(Icons.add)
	onPressed: () => counter.value = counter.value + 1,
)
```

* Alternatively, one can use the `.update` function;
```dart
onPressed: () => counter.update((count) => count + 1),
```
Use the `.modify` method, if the variable is to be modified in place instead of returning new value. Directly operating on `.value` getter doesn't reactively update all the uses.

* Create a live variable that is updated using mapperFunc, whenever parent is updated;

```dart
var x = Live(0);
var xString = x.derive((val) => "$val");
```

* Add custom listener function to a Live variable

```dart
var x = Live(0);
// Store the registration key, which can be used to unregister the listener
var printCallbackKey = x.addListener((newVal) => print("x changed to $newVal"));
// unregister the listener
x.removeListener(printCallbackKey)
```

### LiveList<T>
In a LiveList, you can add listeners for change, remove, insert and move (rearrange) events. A LiveList is backed by a List<T> object.

* Create a LiveList. Assume we have an Entry type for list entries.
```dart
var backingList = await database.fetchEntries();
var entries = LiveList.backedBy(backingList);
```

* Add a change listener to save changed entries to database. A change listener takes as argument index, old value and new value. Note the caveat that, old value and new value can refer to same object if modified in-place using `modifyAt()` method, since dart has reference semantics. Your logic depends on whether the list items are reassigned with operator[]= or modified in-place.

```dart
// Here I assume Entry type is modified in-place.

entries.addChangeListener((_, _, newVal) => database.updateEntry(newVal));

// or if you are reassigning with new object
// you might want to do something like this.

entries.addChangeListener((_, oldVal, newVal) {
	newVal.id = oldVal.id
	database.updateEntry(newVal);
})
```

* Similarly one can add insert, remove and move listeners, more details in documentation or examples. Refresh listeners are called when list is modified using modifyList method, or backingList setter is used.

---

* Create a listView from a LiveList
```dart
entries.listView((entries) => ReorderableListView(
	itemCount: entries.length,
	itemBuilder: (context, i) => ListTile(...), // Build ListTile from entry,
	onReorder: entries.move,
));
```

### Why Live.widget and LiveList.listView methods instead of separate widgets?
You can do that using LiveListView and LiveWidget constructors, but due to some quirks of dart type system, you have to often supply a type parameter, or else the variable in closure will be treated as `dynamic`. Therefore it is more ergonomic to use the extension methods.

## Additional information
This package is written for learning purpose. *This is not to be considered a production-ready package*. Please fill an issue if you notice any bug or sub-optimal code.

