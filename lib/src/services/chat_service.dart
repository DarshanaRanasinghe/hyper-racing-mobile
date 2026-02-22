import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String chatIdFor(String uidA, String uidB) {
    final pair = [uidA, uidB]..sort();
    return '${pair[0]}_${pair[1]}';
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
}
