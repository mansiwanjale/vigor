import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search by Username OR Email
  Future<DocumentSnapshot?> findUser(String query) async {
    // Try username first
    var result = await _db.collection('users').where('username', isEqualTo: query).get();

    // If not found, try email
    if (result.docs.isEmpty) {
      result = await _db.collection('users').where('email', isEqualTo: query).get();
    }

    return result.docs.isNotEmpty ? result.docs.first : null;
  }

  // Create a friendship
  Future<void> addFriend(String friendUid) async {
    String myUid = _auth.currentUser!.uid;

    // We create a unique ID by combining UIDs alphabetically to avoid duplicates
    List<String> ids = [myUid, friendUid]..sort();
    String friendshipId = ids.join('_');

    await _db.collection('friendships').doc(friendshipId).set({
      'participants': ids,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}