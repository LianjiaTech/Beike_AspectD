import 'package:beike_aspectd/aspectd.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:example/hook_example.dart';
import 'receiver_test.dart';

void main() {
  runApp(MyApp());
}

Future<void> appInit() async {
  print('beike example in appInit().');
}

class Observer {
  void onChanged() {}
}

class MyApp extends StatelessWidget {

  static String localHostname = '111';
  String field = '222';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    appInit();

    print(field);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState(i: 19);
}

class _MyHomePageState extends State<MyHomePage> {
  
  int i;
  
  final Receiver receiver = Receiver();
  final dynamic receiver2 = Receiver2();
  final dynamic _receiver6 = Receiver2();
  static const String s = 'fffff';

  _MyHomePageState({this.i = 10});

  void onPluginDemo(int i, _MyHomePageState p) {
    print('[KWLM]:onPluginDemo111 Called!');
  }

  void _incrementCounter() {

    dynamic self = receiver;
    Map info = self.getBasicInfo(PointCut.pointCut());

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      i++;
    });
  }

  void test() {
      _incrementCounter();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    // Receiver rec

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$i',
              style: Theme.of(context).textTheme.display1,
            ),

            GestureDetector(
              child: const Text('onPluginDemo', style: TextStyle(fontSize: 30)),
              onTap: () {
                receiver.receiveTapped(5, j: 9);
                onPluginDemo(4, this);
                // dynamic dynamicO = Receiver();

                // dynamic dynamic2 = Receiver2();
                // dynamic dynamic3 = Receiver3();
                // dynamic dynamic4 = Receiver4();

                // dynamic2.addTestRegularFilterSuper(null);
                // dynamic3.addTestRegularFilterSuper(null);
                // dynamic4.addTestRegularFilterSuper(null);
               
                // dynamicO.addTest(null, '000', s:'666', i:5);
                // dynamicO.addTestRegular(null);
                // receiver2.addTest(null, '111', s:'777', i:8);
                // dynamic d2 = this;
                // d2.addTest();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:(){
          test();
        } ,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
