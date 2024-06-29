import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'LoginPage.dart';
import 'MapPainter.dart';
import 'MenuPage.dart';
import 'RaceResultPage.dart';
import 'RobotConnectionManager.dart';
import 'SpeedSelectPage.dart';
import 'RobotControl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/speed': (context) => SpeedSelectPage(),
        '/menu': (context) => MenuPage(),
        '/create_map': (context) => CreateMapPage(),
        '/maps': (context) => MapsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/mapDetails') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return MapDetailsPage(
                map: args['map'],
                speedFactor: args['speedFactor'],
              );
            },
          );
        }
        assert(false, 'Need to implement ${settings.name}');
        return null;
      },
    );
  }
}

class CreateMapPage extends StatefulWidget {
  @override
  _CreateMapPageState createState() => _CreateMapPageState();
}

class _CreateMapPageState extends State<CreateMapPage> {
  late RobotConnectionManager connectionManager;
  late RobotControl robotControl;
  var imageBytes;
  Image? img;
  double horizontal = 0.0;
  double vertical = 0.0;
  bool isRecording = false;
  List<Map<String, double>> path = [];
  Timer? _timer;
  TextEditingController _mapNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectionManager = RobotConnectionManager(
      url: 'ws://192.168.1.152:9090',
      subscribeHandler: _subscribeHandler,
      subscribeHandler2: _subscribeHandler2,
    );
    connectionManager.connect();
    robotControl = RobotControl(connectionManager.cmd_vel);
  }

  Future<void> _subscribeHandler(Map<String, dynamic> msg) async {
    String imageData = msg['data'];
    setState(() {
      imageBytes = base64.decode(imageData);
    });
  }

  Future<void> _subscribeHandler2(Map<String, dynamic> msg) async {
    var position = msg['pose']['pose']['position'];
    double x = position['x'];
    double y = position['y'];
    setState(() {
      path.add({'x': x, 'y': y});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    connectionManager.disconnect();
    super.dispose();
  }

  void startRecording() {
    setState(() {
      isRecording = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isRecording) {
        connectionManager.odom.subscribe(_subscribeHandler2);
      }
    });
  }

  void stopRecording() async {
    setState(() {
      isRecording = false;
    });
    _timer?.cancel();
    if (imageBytes != null) {
      await _showMapNameDialog();
    } else {
      _showErrorDialog();
    }
  }

  Future<void> _showMapNameDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.orange,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Harita Adı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 20),
                  TextField(
                    style: TextStyle(fontSize: 20.0, color: Colors.white),
                    controller: _mapNameController,
                    decoration: InputDecoration(
                      hintText: "Harita adı girin",
                      hintStyle: TextStyle(fontSize: 20.0, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      savePathToDatabase(_mapNameController.text);
                    },
                    child: Text('Kaydet'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showErrorDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orange,
          title: Text('Hata!',style: TextStyle(color: Colors.red),),
          content: Text('Harita kaydedilemiyor.',style: TextStyle(color: Colors.white,fontSize: 20.0),),
          actions: <Widget>[
            TextButton(
              child: Text('Tamam',style: TextStyle(color: Colors.red),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> savePathToDatabase(String mapName) async {
    if (imageBytes != null && path.isNotEmpty) {
      DatabaseReference mapsRef = FirebaseDatabase.instance.ref().child('maps');
      await mapsRef.push().set({
        'name': mapName,
        'path': path,
      }).then((_) {
        print('Path saved successfully.');
        Navigator.pushNamed(context, '/menu');
      }).catchError((error) {
        print('Failed to save path: $error');
      });
    } else {
      _showErrorDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Object>(
        stream: connectionManager.ros.statusStream,
        builder: (context, snapshot) {
          return Stack(
            children: [
              Center(
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        gaplessPlayback: true,
                        width: 750,
                        fit: BoxFit.fill,
                      )
                    : CircularProgressIndicator(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.home,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 5),
                    IconButton(
                      icon: Icon(
                        isRecording ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: isRecording ? stopRecording : startRecording,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Joystick(
                            mode: JoystickMode.horizontal,
                            listener: (details) {
                              setState(() {
                                horizontal = details.x;
                              });
                              robotControl.move(vertical, horizontal, 0.25);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onLongPressStart: (_) {
                                  setState(() {
                                    vertical = -1.0;
                                  });
                                  robotControl.move(vertical, horizontal, 0.25);
                                },
                                onLongPressEnd: (_) {
                                  setState(() {
                                    vertical = 0.0;
                                  });
                                  robotControl.move(vertical, horizontal, 0.25);
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              GestureDetector(
                                onLongPressStart: (_) {
                                  setState(() {
                                    vertical = 1.0;
                                  });
                                  robotControl.move(vertical, horizontal, 0.25);
                                },
                                onLongPressEnd: (_) {
                                  setState(() {
                                    vertical = 0.0;
                                  });
                                  robotControl.move(vertical, horizontal, 0.25);
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'R',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 35),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class MapsPage extends StatefulWidget {
  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final DatabaseReference _mapsRef =
      FirebaseDatabase.instance.ref().child('maps');
  List<Map<dynamic, dynamic>> maps = [];

  @override
  void initState() {
    super.initState();
    _fetchMaps();
  }

  void _fetchMaps() {
    _mapsRef.once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      List<Map<dynamic, dynamic>> tempMaps = [];
      if (snapshot.value != null) {
        Map<dynamic, dynamic> mapsData = snapshot.value as Map;
        mapsData.forEach((key, value) {
          tempMaps.add({'key': key, 'data': value});
        });
      }
      setState(() {
        maps = tempMaps;
      });
    });
  }

  void _navigateToSpeedSelect(Map<dynamic, dynamic> map) {
    Navigator.pushNamed(
      context,
      '/speed',
      arguments: {'map': map},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.orange,
        elevation: 4, 
        title: Text('Haritalar', style: TextStyle(color: Colors.white)),
      ),
      body: maps.isEmpty
          ? Center(
              child: CircularProgressIndicator(
              color: Colors.white,
            ))
          : ListView.builder(
              itemCount: maps.length,
              itemBuilder: (context, index) {
                String mapName = maps[index]['data']['name'] ?? 'İsimsiz Harita';
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    tileColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.white),
                    ),
                    title: Text(
                      mapName,
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _navigateToSpeedSelect(maps[index]),
                  ),
                );
              },
            ),
    );
  }
}

class MapDetailsPage extends StatefulWidget {
  final Map<dynamic, dynamic> map;
  final double speedFactor;

  MapDetailsPage({required this.map, required this.speedFactor});

  @override
  _MapDetailsPageState createState() => _MapDetailsPageState();
}

class _MapDetailsPageState extends State<MapDetailsPage> {
  late RobotConnectionManager connectionManager;
  late RobotControl robotControl;
  var imageBytes;
  Image? img;
  double horizontal = 0.0;
  double vertical = 0.0;
  ui.Image? image;
  Timer? _timer;
  int countdown = 3;
  bool raceStarted = false;
  Stopwatch stopwatch = Stopwatch();
  String _elapsedTime = "00:00:00";
  Map<String, double> currentPosition = {'x': 0.0, 'y': 0.0};
  bool isOffPath = false; 
  int adjustedMilliseconds = 0;

  @override
  void initState() {
    super.initState();
    connectionManager = RobotConnectionManager(
        url: 'ws://192.168.1.152:9090',
        subscribeHandler: _subscribeHandler,
        subscribeHandler2: _subscribeHandler2);
    connectionManager.connect();
    robotControl = RobotControl(connectionManager.cmd_vel);
    _startImageUpdate();
    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          timer.cancel();
          _startRace();
        }
      });
    });
  }

  void _startRace() {
    if (imageBytes == null) {
      _showErrorDialog('Yarış Başlatılamadı!');
      return;
    }

    setState(() {
      raceStarted = true;
    });
    stopwatch.start();
    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!stopwatch.isRunning) {
        timer.cancel();
      } else {
        setState(() {
          if (isOffPath) {
            adjustedMilliseconds += 1000; 
          } else {
            adjustedMilliseconds += 100; 
          }
          _elapsedTime = _formatElapsedTime(adjustedMilliseconds);
        });
      }
    });
  }

  String _formatElapsedTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$minutesStr:$secondsStr:$hundredsStr";
  }

  void _startImageUpdate() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (imageBytes != null) {
        _updateImage();
      }
    });
  }

  void _updateImage() async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(imageBytes!, (ui.Image img) {
      completer.complete(img);
    });
    image = await completer.future;
    setState(() {});
  }

  Future<void> _subscribeHandler(Map<String, dynamic> msg) async {
    String imageData = msg['data'];
    setState(() {
      imageBytes = base64.decode(imageData);
    });
  }

  Future<void> _subscribeHandler2(Map<String, dynamic> msg) async {
    var position = msg['pose']['pose']['position'];
    double x = position['x'];
    double y = position['y'];
    setState(() {
      currentPosition = {'x': x, 'y': y};
    });

    List<dynamic> path = widget.map['data']['path'] ?? [];
    if (path.isNotEmpty) {
      var lastPoint = path.last;
      double lastX = lastPoint['x'];
      double lastY = lastPoint['y'];

      double tolerance = 0.1;
      if ((x - lastX).abs() < tolerance && (y - lastY).abs() < tolerance) {
        _finishRace(widget.map['data']['name']);
      }
    }

    _checkOffPath(path);
  }

  void _checkOffPath(List<dynamic> path) {
    bool offPath = true;
    double tolerance = 0.1; 

    for (var point in path) {
      if ((currentPosition['x']! - point['x']).abs() < tolerance &&
          (currentPosition['y']! - point['y']).abs() < tolerance) {
        offPath = false;
        break;
      }
    }

    setState(() {
      isOffPath = offPath;
    });
  }

  void _finishRace(String mapName) {
    stopwatch.stop();
    String finalTime = _elapsedTime;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RaceResultPage(elapsedTime: finalTime, mapName: mapName),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.orange,
          title: Text('Hata!', style: TextStyle(fontSize: 40, color: Colors.red)),
          content: Text(message, style: TextStyle(fontSize: 20, color: Colors.white)),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Tamam', style: TextStyle(fontSize: 20, color: Colors.orange)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    connectionManager.disconnect();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> path = widget.map['data']['path'] ?? [];

    return Scaffold(
      backgroundColor: Colors.orange,
      body: Stack(
        children: [
          Center(
            child: image != null
                ? CustomPaint(
                    size: Size(MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height),
                    painter: MapPainter(
                        image: image!, path: path, rotationAngle: 3.14 / 2, currentPosition: currentPosition),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : CircularProgressIndicator(color: Colors.white),
          ),
          if (countdown > 0)
            Center(
              child: Text(
                countdown.toString(),
                style: TextStyle(fontSize: 96, color: Colors.white),
              ),
            ),
          if (raceStarted)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.home,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.orange),
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    width: 150,
                    height: 50,
                    color: Colors.white.withOpacity(0.0),
                    child: Center(
                      child: Text(
                        _elapsedTime,
                        style: TextStyle(
                          color: isOffPath ? Colors.red : Colors.white, 
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (raceStarted)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Joystick(
                        mode: JoystickMode.horizontal,
                        listener: (details) {
                          setState(() {
                            horizontal = details.x;
                          });
                          robotControl.move(
                              vertical, horizontal, widget.speedFactor);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onLongPressStart: (_) {
                              setState(() {
                                vertical = -1.0;
                              });
                              robotControl.move(
                                  vertical, horizontal, widget.speedFactor);
                            },
                            onLongPressEnd: (_) {
                              setState(() {
                                vertical = 0.0;
                              });
                              robotControl.move(
                                  vertical, horizontal, widget.speedFactor);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          GestureDetector(
                            onLongPressStart: (_) {
                              setState(() {
                                vertical = 1.0;
                              });
                              robotControl.move(
                                  vertical, horizontal, widget.speedFactor);
                            },
                            onLongPressEnd: (_) {
                              setState(() {
                                vertical = 0.0;
                              });
                              robotControl.move(
                                  vertical, horizontal, widget.speedFactor);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  'R',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
