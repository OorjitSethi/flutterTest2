import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'services/signaling.dart';
import 'package:firebase_database/firebase_database.dart';

class BroadcasterPage extends StatefulWidget {
  @override
  _BroadcasterPageState createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends State<BroadcasterPage> {
  String sessionId = Uuid().v4();
  Signaling? signaling;

  @override
  void initState() {
    super.initState();
    startBroadcast();
  }

  void startBroadcast() async {
    signaling = Signaling(sessionId: sessionId);
    await signaling!.createOffer((offer) {
      // Send offer to Firebase
      FirebaseDatabase.instance.ref('sessions/$sessionId/offer').set({
        'sdp': offer.sdp,
        'type': offer.type,
      });
    });
  }

  @override
  void dispose() {
    signaling?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Broadcasting Screen'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Scan this QR code to view the screen:'),
            QrImage(
              data: sessionId,
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Stop Sharing'),
              onPressed: () {
                signaling?.dispose();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
