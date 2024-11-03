import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/signaling.dart';
import 'qr_scan_page.dart';

class ViewerPage extends StatefulWidget {
  @override
  _ViewerPageState createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Signaling? signaling;
  String? sessionId;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    signaling?.dispose();
    super.dispose();
  }

  void _joinSession(String sessionId) async {
    this.sessionId = sessionId;
    signaling = Signaling(sessionId: sessionId);

    signaling!.onAddRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };

    // Retrieve the offer from Firebase
    var snapshot = await FirebaseDatabase.instance.ref('sessions/$sessionId/offer').get();

    if (snapshot.exists && snapshot.value != null) {
      var data = Map<String, dynamic>.from(snapshot.value as Map);
      await signaling!.createAnswer(data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session not found')),
      );
    }
  }

  void _scanQRCode() async {
    String? sessionId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScanPage()),
    );

    if (sessionId != null) {
      _joinSession(sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viewing Screen'),
      ),
      body: Center(
        child: _remoteRenderer.srcObject != null
            ? RTCVideoView(_remoteRenderer)
            : ElevatedButton(
                child: Text('Scan QR Code'),
                onPressed: _scanQRCode,
              ),
      ),
    );
  }
}
