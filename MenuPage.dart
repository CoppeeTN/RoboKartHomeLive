import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
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
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/create_map');
                  },
                  child: Text('Harita Oluştur'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/maps');
                  },
                  child: Text('Haritalar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
