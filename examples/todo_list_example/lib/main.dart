import 'package:flutter/material.dart';
import 'package:livestate/livestate.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Minimal Todo List application using LiveList
// Allows to add, delete, mark, reorder

class TodoItem {
  TodoItem({required this.title, required this.isFinished});
  bool isFinished;
  String title;

  static TodoItem fromString(String s) {
    var index = s.indexOf('|');
    var title = s.substring(index + 1);
    var isFinished = s.substring(0, index) == 'true';
    return TodoItem(title: title, isFinished: isFinished);
  }

  @override
  String toString() => "$isFinished|$title";
}

// For simplicity, make the sharedpreferences object global and initialize it in main
late SharedPreferences prefs;

LiveList<TodoItem> loadItems() {
  var entries = LiveList.backedBy(
    (prefs.getStringList('entries') ?? []).map(TodoItem.fromString).toList(),
  );

  // For simplicity we are just rewriting the entire list
  // But one can use the parameters passed in callbacks
  entries.addChangeListener((i, o, n) => writeList(prefs, entries));
  entries.addRemoveListener((i, o) => writeList(prefs, entries));
  entries.addInsertListener((i, n) => writeList(prefs, entries));
  entries.addMoveListener((o, n, t) => writeList(prefs, entries));
  entries.addRefreshListener((l) => writeList(prefs, entries));
  return entries;
}

void writeList(SharedPreferences prefs, LiveList<TodoItem> list) {
  prefs.setStringList('entries', list.map((t) => t.toString()).toList());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListHomePage(title: 'LiveState Todo List'),
    );
  }
}

class TodoListHomePage extends StatelessWidget {
  const TodoListHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    var entries = loadItems();
    var textCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text("LiveState To-do List"),
      ),
      body: entries.listView((es) => ReorderableListView.builder(
            header: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                    controller: textCtrl,
                  )),
                  IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.green[800],
                      onPressed: () {
                        var index = es.backingList
                            .indexWhere((t) => t.title == textCtrl.text);
                        if (textCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please enter a task!"),
                                  duration: Duration(milliseconds: 500)));
                        } else if (index != -1) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text("Item already exists in list"),
                            duration: Duration(milliseconds: 500),
                          ));
                          return;
                        } else {
                          es.add(
                              // 0,
                              TodoItem(
                                  title: textCtrl.text, isFinished: false));
                          textCtrl.clear();
                        }
                      }),
                ])),
            itemCount: es.length,
            // ItemBuilder building from end of the list.
            // In this example, probably it doesn't make any difference.
            // But might need this in an application, where it makes
            // sense to show the newly appended objects on top.
            // The i'th list tile is created from element at es.length - 1 - i,
            // also note the arguments to move;
            itemBuilder: (context, i) => CheckboxListTile(
              key: Key(es[es.length - i - 1].toString()),
              onChanged: (s) => es.modifyAt(
                  es.length - i - 1, (t) => t.isFinished = s ?? t.isFinished),
              value: es[es.length - i - 1].isFinished,
              title: Text(es[es.length - i - 1].title),
              controlAffinity: ListTileControlAffinity.leading,
              secondary: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    es.removeAt(es.length - i - 1);
                  }),
            ),
            // map range 0 .. len-1 to len-1 .. 0
            // map range 0 .. len to len .. 0
            onReorder: (o, n) => es.move(es.length - o - 1, es.length - n),
          )),
    );
  }
}
