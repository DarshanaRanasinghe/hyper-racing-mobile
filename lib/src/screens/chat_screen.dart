import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

class ChatScreenArgs {
  final String otherUid;
  final String otherName;
  ChatScreenArgs({required this.otherUid, required this.otherName});
}

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = AuthService();
  final _chat = ChatService();
  final _users = UserService();
  final _msgCtrl = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatLastSeen(Timestamp ts) {
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _send(String chatId, String meUid, String otherUid) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      await _chat.sendMessage(
        chatId: chatId,
        senderId: meUid,
        receiverId: otherUid,
        text: text,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _clearChat(String chatId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will delete all messages in this chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _chat.clearChat(chatId: chatId);

    if (!mounted) return;
    Navigator.pop(context); // go back to home after clearing
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ChatScreenArgs;
    final me = _auth.currentUser;

    if (me == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final chatId = _chat.chatIdFor(me.uid, args.otherUid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _users.userDocStream(args.otherUid),
          builder: (context, snap) {
            AppUser? other;
            if (snap.hasData && snap.data!.exists) {
              other = AppUser.fromMap(
                args.otherUid,
                snap.data!.data() as Map<String, dynamic>,
              );
            }

            final photoUrl = (other?.photoUrl ?? '').trim();
            final online = other?.online ?? false;
            final lastSeen = other?.lastSeen;

            final statusText = online
                ? 'Online'
                : (lastSeen == null
                      ? 'Offline'
                      : 'Last seen ${_formatLastSeen(lastSeen)}');

            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          args.otherName.isNotEmpty
                              ? args.otherName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(args.otherName, overflow: TextOverflow.ellipsis),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        // ✅ No call/video icons
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear') _clearChat(chatId);
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'clear', child: Text('Clear chat')),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chat.messagesStream(chatId: chatId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snap.data!.docs
                    .map((d) => ChatMessage.fromDoc(d))
                    .toList();

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final isMe = m.senderId == me.uid;

                    return _Bubble(
                      text: m.text,
                      isMe: isMe,
                      timeText: _formatTime(m.createdAt),
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: AppColors.subtext),
                        filled: true,
                        fillColor: AppColors.bubbleOther,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _sending
                          ? null
                          : () => _send(chatId, me.uid, args.otherUid),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        backgroundColor: AppColors.purple,
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String timeText;

  const _Bubble({
    required this.text,
    required this.isMe,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 8),
      bottomRight: Radius.circular(isMe ? 8 : 18),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: isMe ? AppColors.bubbleMe : AppColors.bubbleOther,
            borderRadius: radius,
          ),
          child: Text(text, style: const TextStyle(color: AppColors.text)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
          child: Text(
            timeText,
            style: const TextStyle(color: AppColors.subtext, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
