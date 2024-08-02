import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMessages() {
    return _db.collection('messages').orderBy('timestamp').snapshots();
  }

  Future<void> sendMessage(String message, String userId, {bool isLocation = false, GeoPoint? location}) async {
    await _db.collection('messages').add({
      'message': message,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'isLocation': isLocation,
      'location': isLocation && location != null ? {
        'latitude': location.latitude,
        'longitude': location.longitude,
      } : null,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _db.collection('messages').doc(messageId).delete();
  }

  Future<void> updateUserLocation(String userId, GeoPoint location) async {
    await _db.collection('users').doc(userId).update({
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    });
  }
}
