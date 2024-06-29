import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RaceResultPage extends StatelessWidget {
  final String elapsedTime;
  final String mapName;

  RaceResultPage({required this.elapsedTime, required this.mapName});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.orange,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Yarış Tamamlandı!',
                style: TextStyle(fontSize: 48, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                '$elapsedTime',
                style: TextStyle(fontSize: 28, color: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(
                style: TextStyle(color: Colors.white),
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Isminizi Giriniz:',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String name = nameController.text;
                  if (name.isNotEmpty) {
                    _saveResultToDatabase(name, elapsedTime, mapName).then((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowResultPage(mapName: mapName),
                        ),
                      );
                    });
                  }
                },
                child: Text(
                  'Kaydet',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveResultToDatabase(String name, String elapsedTime, String mapName) async {
    DatabaseReference resultsRef =
        FirebaseDatabase.instance.ref().child('results');
    await resultsRef.push().set({
      'name': name,
      'elapsedTime': elapsedTime,
      'mapName': mapName,
    }).then((_) {
      print('Result saved successfully.');
    }).catchError((error) {
      print('Failed to save result: $error');
    });
  }
}

class ShowResultPage extends StatelessWidget {
  final String mapName;

  ShowResultPage({required this.mapName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Skor Tablosu',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ResultsTable(mapName: mapName),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 15.0, top: 40),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            );
                          },
                          child: Text(
                            'Yeniden Oyna',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultsTable extends StatefulWidget {
  final String mapName;

  ResultsTable({required this.mapName});

  @override
  _ResultsTableState createState() => _ResultsTableState();
}

class _ResultsTableState extends State<ResultsTable> {
  final DatabaseReference _resultsRef =
      FirebaseDatabase.instance.ref().child('results');
  List<Map<dynamic, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  void _fetchResults() {
    _resultsRef.orderByChild('mapName').equalTo(widget.mapName).once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      List<Map<dynamic, dynamic>> tempResults = [];
      if (snapshot.value != null) {
        Map<dynamic, dynamic> resultsData = snapshot.value as Map;
        resultsData.forEach((key, value) {
          tempResults.add({'key': key, 'data': value});
        });
      }
      setState(() {
        results = tempResults;
        results.sort((a, b) {
          Duration durationA = _parseElapsedTime(a['data']['elapsedTime']);
          Duration durationB = _parseElapsedTime(b['data']['elapsedTime']);
          return durationA.compareTo(durationB);
        });
      });
    });
  }

  Duration _parseElapsedTime(String elapsedTime) {
    List<String> parts = elapsedTime.split(':');
    int minutes = int.parse(parts[0]);
    int seconds = int.parse(parts[1]);
    int milliseconds = int.parse(parts[2]);
    return Duration(
        minutes: minutes, seconds: seconds, milliseconds: milliseconds * 10);
  }

  @override
  Widget build(BuildContext context) {
    return results.isEmpty
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: [
                DataColumn(
                    label: Text('İSİM',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0))),
                DataColumn(
                    label: Text('YARIŞ SÜRESİ',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0))),
              ],
              rows: results.map((result) {
                return DataRow(cells: [
                  DataCell(Text(result['data']['name'],
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0))),
                  DataCell(Text(result['data']['elapsedTime'],
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0))),
                ]);
              }).toList(),
            ),
          );
  }
}
