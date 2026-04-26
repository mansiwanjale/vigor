import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import 'dart:math';

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


  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final code = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    final nums = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    return '$code-$nums';
  }

  Future<String> createTribe({
    required String name,
    required String description,
    required String category,
  }) async {
    if (name.trim().isEmpty) throw "Tribe name can't be empty";
    if (name.trim().length < 3) throw "Name must be at least 3 characters";

    // Check name not already taken
    var existing = await _db
        .collection('tribes')
        .where('name', isEqualTo: name.trim())
        .get();
    if (existing.docs.isNotEmpty) throw "That tribe name is already taken!";

    final inviteCode = _generateInviteCode();
    final ref = await _db.collection('tribes').add({
      'name': name.trim(),
      'description': description.trim(),
      'category': category,
      'owner': _me,
      'members': [_me],
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> joinTribeByCode(String code) async {
    final q = await _db
        .collection('tribes')
        .where('inviteCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (q.docs.isEmpty) throw "Invalid invite code";

    final tribeDoc = q.docs.first;
    final members = List<String>.from(tribeDoc['members'] ?? []);
    if (members.contains(_me)) throw "You're already in this tribe!";

    await _db.collection('tribes').doc(tribeDoc.id).update({
      'members': FieldValue.arrayUnion([_me]),
    });
  }

  Future<void> inviteFriendToTribe(String tribeId, String friendUsername) async {
    // Verify caller is owner or member
    final tribe = await _db.collection('tribes').doc(tribeId).get();
    if (!tribe.exists) throw "Tribe not found";

    final members = List<String>.from(tribe['members'] ?? []);
    if (members.contains(friendUsername)) throw "${friendUsername} is already in this tribe!";

    await _db.collection('tribes').doc(tribeId).update({
      'members': FieldValue.arrayUnion([friendUsername]),
    });
  }

  Future<void> leaveTribe(String tribeId) async {
    final tribe = await _db.collection('tribes').doc(tribeId).get();
    if (tribe['owner'] == _me) throw "You're the owner — delete the tribe or transfer ownership first";

    await _db.collection('tribes').doc(tribeId).update({
      'members': FieldValue.arrayRemove([_me]),
    });
  }

  Future<void> removeMember(String tribeId, String username) async {
    final tribe = await _db.collection('tribes').doc(tribeId).get();
    if (tribe['owner'] != _me) throw "Only the owner can remove members";
    if (username == _me) throw "You can't remove yourself";

    await _db.collection('tribes').doc(tribeId).update({
      'members': FieldValue.arrayRemove([username]),
    });
  }

  Future<void> deleteTribe(String tribeId) async {
    final tribe = await _db.collection('tribes').doc(tribeId).get();
    if (tribe['owner'] != _me) throw "Only the owner can delete this tribe";

    await _db.collection('tribes').doc(tribeId).delete();
  }

  // ── Tribe Streams ────────────────────────────────────────
  Stream<QuerySnapshot> get myTribes => _db
      .collection('tribes')
      .where('members', arrayContains: _me)
      .snapshots();

  Stream<QuerySnapshot> getTribeMessages(String tribeId) => _db
      .collection('tribes')
      .doc(tribeId)
      .collection('chat')
      .orderBy('sentAt', descending: false)
      .snapshots();

  Future<void> sendTribeMessage(String tribeId, String text) async {
    await _db
        .collection('tribes')
        .doc(tribeId)
        .collection('chat')
        .add({
      'from': _me,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  // Get my friends list (for invite picker)
  Future<List<String>> getMyFriendUsernames() async {
    final snap = await _db
        .collection('friendships')
        .where('participants', arrayContains: _me)
        .get();

    return snap.docs.map((doc) {
      final participants = List<String>.from(doc['participants']);
      return participants.firstWhere((p) => p != _me);
    }).toList();
  }

}

