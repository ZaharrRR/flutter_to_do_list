import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка уведомлений
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student To-Do List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todoItems = [];
  bool _isSorted = false;

  void _sortTasksByDeadline() {
    setState(() {
      _todoItems.sort((a, b) => a.deadline.compareTo(b.deadline));
      _isSorted = true;
    });
  }

  void _resetSort() {
    setState(() {
      _isSorted = false;
    });
  }

  void _checkDeadlines(List<TodoItem> tasks) {
    final now = DateTime.now();
    for (final task in tasks) {
      final difference = task.deadline.difference(now).inHours;
      if (difference <= 24 && difference >= 0) {
        _showNotification(task.task, task.deadline);
      }
    }
  }

  void _showNotification(String task, DateTime deadline) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Напоминание о задаче',
      'Задача "$task" скоро истекает (${DateFormat('yyyy-MM-dd').format(deadline)})',
      platformChannelSpecifics,
    );
  }

  void _addTodoItem(String task, DateTime deadline) {
    setState(() {
      _todoItems.add(TodoItem(task: task, deadline: deadline));
      _checkDeadlines(_todoItems);
    });
  }

  void _editTodoItem(int index, String newTask, DateTime newDeadline) {
    setState(() {
      _todoItems[index].task = newTask;
      _todoItems[index].deadline = newDeadline;
      _checkDeadlines(_todoItems);
    });
  }

  void _deleteTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
  }

  void _showAddTodoDialog() {
    String newTask = '';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить задачу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Задача'),
                onChanged: (value) {
                  newTask = value;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                  }
                },
                child: Text('Выбрать дедлайн'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                if (newTask.isNotEmpty) {
                  _addTodoItem(newTask, selectedDate);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTodoDialog(int index) {
    String updatedTask = _todoItems[index].task;
    DateTime updatedDeadline = _todoItems[index].deadline;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать задачу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Задача'),
                controller: TextEditingController(text: updatedTask),
                onChanged: (value) {
                  updatedTask = value;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: updatedDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    updatedDeadline = pickedDate;
                  }
                },
                child: Text('Изменить дедлайн'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                if (updatedTask.isNotEmpty) {
                  _editTodoItem(index, updatedTask, updatedDeadline);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список задач'),
        actions: [
          IconButton(
            icon: Icon(_isSorted ? Icons.refresh : Icons.sort),
            onPressed: _isSorted ? _resetSort : _sortTasksByDeadline,
            tooltip:
                _isSorted ? 'Сбросить сортировку' : 'Сортировать по дедлайну',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _todoItems.length,
        itemBuilder: (context, index) {
          final item = _todoItems[index];
          return ListTile(
            title: Text(item.task),
            subtitle: Text(
              'Дедлайн: ${DateFormat('yyyy-MM-dd').format(item.deadline)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditTodoDialog(index);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteTodoItem(index);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

class TodoItem {
  String task;
  DateTime deadline;

  TodoItem({required this.task, required this.deadline});
}
