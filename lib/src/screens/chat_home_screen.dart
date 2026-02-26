import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  static const routeName = '/chat-home';
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen>
    with WidgetsBindingObserver {
  final _auth = AuthService();
  final _users = UserService();
  final _chat = ChatService();
  final _searchCtrl = TextEditingController();

  String _query = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _setOnline(true);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnline(false);
    }
  }

  Future<void> _setOnline(bool online) async {
    final me = _auth.currentUser;
    if (me == null) return;
    await _users.setPresence(uid: me.uid, online: online);
  }

  Future<void> _logout() async {
    await _setOnline(false);
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  void _openChat(AppUser u) {
    Navigator.pushNamed(
      context,
      ChatScreen.routeName,
      arguments: ChatScreenArgs(otherUid: u.uid, otherName: u.username),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser;
    if (me == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyper Chat'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          // HEADER AREA (purple) + avatars row like the image
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Chat with\nyour friends',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                // ✅ Toggleable search bar (only when pressing search icon)
                if (_showSearch) ...[
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search username...',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.12),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ✅ Avatars row:
                // Left: search icon
                // Right: ONLY unchatted users
                SizedBox(
                  height: 56,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _users.usersStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      final allUsers = snap.data!.docs
                          .where((d) => d.id != me.uid)
                          .map(
                            (d) => AppUser.fromMap(
                              d.id,
                              d.data() as Map<String, dynamic>,
                            ),
                          )
                          .where(
                            (u) => _query.isEmpty
                                ? true
                                : u.username.toLowerCase().contains(_query),
                          )
                          .toList();

                      return Row(
                        children: [
                          // search icon like the image
                          InkWell(
                            onTap: () =>
                                setState(() => _showSearch = !_showSearch),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.16),
                              child: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: allUsers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final u = allUsers[i];
                                final chatId = _chat.chatIdFor(me.uid, u.uid);

                                // show ONLY if chat doc does NOT exist => unchatted
                                return StreamBuilder<DocumentSnapshot>(
                                  stream: _chat.chatDocStream(chatId),
                                  builder: (context, chatSnap) {
                                    final chatted =
                                        chatSnap.hasData &&
                                        chatSnap.data!.exists;
                                    if (chatted) return const SizedBox.shrink();

                                    final photoUrl = (u.photoUrl ?? '').trim();

                                    return InkWell(
                                      onTap: () => _openChat(u),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.18),
                                        backgroundImage: photoUrl.isNotEmpty
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl.isEmpty
                                            ? Text(
                                                u.username.isNotEmpty
                                                    ? u.username[0]
                                                          .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Bottom list = ONLY previously chatted users
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _users.usersStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snap.data!.docs
                    .where((d) => d.id != me.uid)
                    .map(
                      (d) => AppUser.fromMap(
                        d.id,
                        d.data() as Map<String, dynamic>,
                      ),
                    )
                    .where(
                      (u) => _query.isEmpty
                          ? true
                          : u.username.toLowerCase().contains(_query),
                    )
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final chatId = _chat.chatIdFor(me.uid, u.uid);

                    // Show only if chatted (chat doc exists)
                    return StreamBuilder<DocumentSnapshot>(
                      stream: _chat.chatDocStream(chatId),
                      builder: (context, chatSnap) {
                        final chatted =
                            chatSnap.hasData && chatSnap.data!.exists;
                        if (!chatted) return const SizedBox.shrink();

                        // last message + time
                        String lastMsg = 'Tap to chat';
                        String timeText = '';
                        if (chatSnap.data!.exists) {
                          final data =
                              chatSnap.data!.data() as Map<String, dynamic>;
                          lastMsg = (data['lastMessage'] ?? 'Tap to chat')
                              .toString();
                          final ts = data['lastMessageAt'];
                          if (ts is Timestamp) timeText = _formatChatTime(ts);
                        }

                        final photoUrl = (u.photoUrl ?? '').trim();

                        return ListTile(
                          tileColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.purpleAccent
                                    .withOpacity(0.20),
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty
                                    ? Text(
                                        u.username.isNotEmpty
                                            ? u.username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: u.online
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.card,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            u.username,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            u.online ? 'Online' : lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.subtext),
                          ),
                          trailing: Text(
                            timeText,
                            style: const TextStyle(
                              color: AppColors.subtext,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => _openChat(u),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatChatTime(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    final sameDay =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;

    if (sameDay) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$d/$mo';
    }
  }
}
