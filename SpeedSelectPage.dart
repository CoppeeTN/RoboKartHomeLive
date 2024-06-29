import 'package:flutter/material.dart';

class SpeedSelectPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Map<dynamic, dynamic> map = arguments['map'];

    return Scaffold(
      backgroundColor: Colors.orange,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Robot hızını seçiniz',
                  style: TextStyle(color: Colors.white, fontSize: 40),
                ),
                SizedBox(height: 20), 
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/mapDetails',
                      arguments: {'map': map, 'speedFactor': 0.3},
                    );
                  },
                  child: Text('0.3 m/s',style: TextStyle(fontSize: 20),),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/mapDetails',
                      arguments: {'map': map, 'speedFactor': 0.5},
                    );
                  },
                  child: Text('0.5 m/s',style: TextStyle(fontSize: 20),),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/mapDetails',
                      arguments: {'map': map, 'speedFactor': 1.0},
                    );
                  },
                  child: Text('1.0 m/s',style: TextStyle(fontSize: 20),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
