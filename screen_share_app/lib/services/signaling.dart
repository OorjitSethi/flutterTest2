import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

class Signaling {
  final _databaseReference = FirebaseDatabase.instance.ref();
  final String sessionId;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Function(MediaStream stream)? onAddRemoteStream;

  Signaling({required this.sessionId});

  Future<void> createOffer(Function(RTCSessionDescription sdp) onOfferCreated) async {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };

  _peerConnection = await createPeerConnection(configuration);

  _localStream = await navigator.mediaDevices.getDisplayMedia({
    'audio': false,
    'video': true,
  });

  _peerConnection!.addStream(_localStream!);

  RTCSessionDescription offer = await _peerConnection!.createOffer();
  await _peerConnection!.setLocalDescription(offer);

  onOfferCreated(offer);

  _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
    _databaseReference.child('sessions/$sessionId/callerCandidates').push().set(candidate.toMap());
  };

  // Listen for Answer
  _databaseReference.child('sessions/$sessionId/answer').onValue.listen((event) async {
    var data = event.snapshot.value as Map?;
    if (data != null) {
      RTCSessionDescription answer = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection!.setRemoteDescription(answer);
    }
  });

  // Listen for Remote ICE Candidates
  _databaseReference.child('sessions/$sessionId/calleeCandidates').onChildAdded.listen((event) {
    var data = event.snapshot.value as Map?;
    if (data != null) {
      RTCIceCandidate candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      _peerConnection!.addCandidate(candidate);
    }
  });
}


  Future<void> createAnswer(Map<String, dynamic> remoteOffer) async {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };

  _peerConnection = await createPeerConnection(configuration);

  _peerConnection!.onAddStream = (MediaStream stream) {
    if (onAddRemoteStream != null) {
      onAddRemoteStream!(stream);
    }
  };

  RTCSessionDescription offer = RTCSessionDescription(remoteOffer['sdp'], remoteOffer['type']);
  await _peerConnection!.setRemoteDescription(offer);

  RTCSessionDescription answer = await _peerConnection!.createAnswer();
  await _peerConnection!.setLocalDescription(answer);

  // Send the answer to Firebase
  _databaseReference.child('sessions/$sessionId/answer').set(answer.toMap());

  _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
    _databaseReference.child('sessions/$sessionId/calleeCandidates').push().set(candidate.toMap());
  };

  // Listen for Remote ICE Candidates
  _databaseReference.child('sessions/$sessionId/callerCandidates').onChildAdded.listen((event) {
    var data = event.snapshot.value as Map?;
    if (data != null) {
      RTCIceCandidate candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      _peerConnection!.addCandidate(candidate);
    }
  });
}


  // Additional methods for managing ICE candidates, streams, etc.
  void dispose() {
    _peerConnection?.close();
    _localStream?.dispose();
  }
}
