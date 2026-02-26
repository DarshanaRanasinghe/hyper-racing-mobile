import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String chatIdFor(String uidA, String uidB) {
    final pair = [uidA, uidB]..sort();
    return '${pair[0]}_${pair[1]}';
  }

  Stream<DocumentSnapshot> chatDocStream(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }

  Stream<QuerySnapshot> messagesStream({required String chatId}) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final now = FieldValue.serverTimestamp();

    // Ensure chat exists + update last message
    await chatRef.set({
      'participants': [senderId, receiverId],
      'lastMessage': trimmed,
      'lastMessageAt': now,
    }, SetOptions(merge: true));

    await msgRef.set({
      'text': trimmed,
      'senderId': senderId,
      'receiverId': receiverId,
      'createdAt': now,
    });
  }

  Future<void> clearChat({required String chatId}) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgCol = chatRef.collection('messages');

    // Delete messages in batches (safe for many messages)
    while (true) {
      final snap = await msgCol.limit(200).get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    // Delete chat document itself
    await chatRef.delete();
  }
}
