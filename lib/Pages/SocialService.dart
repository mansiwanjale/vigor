import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _me => Session().currentUsername;

  // ── Search ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> findUser(String query) async {
    // Try by username (doc ID)
    var doc = await _db.collection('users').doc(query).get();
    if (doc.exists) return {'id': doc.id, ...doc.data()!};

    // Try by email
    var q = await _db
        .collection('users')
        .where('email', isEqualTo: query)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      return {'id': q.docs.first.id, ...q.docs.first.data()};
    }
    return null;
  }

  // ── Friend Requests ─────────────────────────────────────
  Future<void> sendFriendRequest(String toUsername) async {
    // Don't send to yourself
    if (toUsername == _me) throw "You can't add yourself!";

    // Check if already friends
    List<String> ids = [_me, toUsername]..sort();
    var friendship = await _db
        .collection('friendships')
        .doc(ids.join('_'))
        .get();
    if (friendship.exists) throw "You're already friends!";

    // Check if request already pending
    var existing = await _db
        .collection('friend_requests')
        .where('from', isEqualTo: _me)
        .where('to', isEqualTo: toUsername)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existing.docs.isNotEmpty) throw "Request already sent!";

    await _db.collection('friend_requests').add({
      'from': _me,
      'to': toUsername,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptRequest(String docId, String fromUsername) async {
    // Mark request as accepted
    await _db.collection('friend_requests').doc(docId).update({
      'status': 'accepted',
    });

    // Create friendship
    List<String> ids = [_me, fromUsername]..sort();
    await _db.collection('friendships').doc(ids.join('_')).set({
      'participants': ids,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineRequest(String docId) async {
    await _db
        .collection('friend_requests')
        .doc(docId)
        .update({'status': 'declined'});
  }

  // ── Streams (real-time) ──────────────────────────────────
  Stream<QuerySnapshot> get incomingRequests => _db
      .collection('friend_requests')
      .where('to', isEqualTo: _me)
      .where('status', isEqualTo: 'pending')
      .snapshots();

  Stream<QuerySnapshot> get myFriends => _db
      .collection('friendships')
      .where('participants', arrayContains: _me)
      .snapshots();

  // ── Chat ─────────────────────────────────────────────────
  String chatId(String otherUsername) {
    List<String> ids = [_me, otherUsername]..sort();
    return ids.join('_');
  }

  Stream<QuerySnapshot> getMessages(String otherUsername) => _db
      .collection('chats')
      .doc(chatId(otherUsername))
      .collection('messages')
      .orderBy('sentAt', descending: false)
      .snapshots();

  Future<void> sendMessage(String toUsername, String text) async {
    await _db
        .collection('chats')
        .doc(chatId(toUsername))
        .collection('messages')
        .add({
      'from': _me,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }
}