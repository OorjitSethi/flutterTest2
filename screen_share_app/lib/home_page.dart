import 'package:flutter/material.dart';
import 'package:screen_share_app/broadcaster_page.dart';
import 'package:screen_share_app/viewer_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Screen Share App'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              child: Text('Share Screen'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BroadcasterPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('View Screen'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewerPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
