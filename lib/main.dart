import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List _todoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((value) {
      setState(() {
        _todoList = json.decode(value!);
      });
    });
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newtodo = Map();
      newtodo["title"] = _todoController.text;
      _todoController.text = "";
      newtodo["ok"] = false;
      _todoList.add(newtodo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lista de tarefas'),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: Column(
        children: [
          _todoList.isEmpty ?
              Container(
                padding: const EdgeInsets.fromLTRB(0.0, 50.0, 0.0, 0.0),
                alignment: Alignment.center,
                child: const Text(
                  "Sem tarefas!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 35, color: Colors.black54),
                ),
              )
              :
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: buildItemList,
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green[700],
          onPressed: () => _displayDialog(context),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          )),
    );
  }

  Future<Future> _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Nova tarefa'),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _todoController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Insira uma tarefa";
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                    labelText: "nome...",
                    labelStyle: TextStyle(color: Colors.grey[700], fontSize: 20)),
                style: const TextStyle(fontSize: 25),
              ),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    fixedSize: const Size(80, 45),
                    primary: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    )),
                child: const Text(
                  'Salvar',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _addTodo();
                    Navigator.of(context).pop();
                  }
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    fixedSize: const Size(80, 45),
                    primary: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    )),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white,),),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Widget buildItemList(BuildContext context, int index) {
    return Dismissible(
      background: Container(
        color: Colors.red[700],
        child: const Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            )),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
            _todoList[index]["ok"] ? Icons.check : Icons.error,
            color: Colors.white,
          ),
          backgroundColor: Colors.green[700],
        ),
        onChanged: (check) {
          setState(() {
            _todoList[index]["ok"] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) => {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPosition = index;
          _todoList.removeAt(index);
          _saveData();

          final snackbar = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPosition, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snackbar);
        })
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
