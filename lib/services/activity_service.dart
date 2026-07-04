import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String get _uid => _auth.currentUser?.uid ?? '';

  static Future<void> addActivity(String title,
      {String subtitle = '', String type = 'chat'}) async {
    if (_uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('activities')
        .add({
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'time': Timestamp.now(),
    });
  }

  static Future<void> incrementChats() async {
    if (_uid.isEmpty) return;
    await _firestore.collection('users').doc(_uid).set({
      'chatCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // incrementQuizzes correctly writes to 'quizCount'
  static Future<void> incrementQuizzes() async {
    if (_uid.isEmpty) return;
    await _firestore.collection('users').doc(_uid).set({
      'quizCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  //  PDF count tracking
  static Future<void> incrementPdfs() async {
    if (_uid.isEmpty) return;
    await _firestore.collection('users').doc(_uid).set({
      'pdfCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  //  Tracks real minutes, not fake "1 hour"
  static Future<void> addStudyMinutes(int minutes) async {
    if (_uid.isEmpty || minutes <= 0) return;
    await _firestore.collection('users').doc(_uid).set({
      'studyMinutes': FieldValue.increment(minutes),
    }, SetOptions(merge: true));
  }
}