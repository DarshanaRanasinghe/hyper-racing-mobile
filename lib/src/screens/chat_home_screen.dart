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
          // Header + search
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
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search username...',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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

                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final chatId = _chat.chatIdFor(me.uid, u.uid);

                    return _ChatListTile(
                      user: u,
                      chatId: chatId,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          ChatScreen.routeName,
                          arguments: ChatScreenArgs(
                            otherUid: u.uid,
                            otherName: u.username,
                          ),
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
}

class _ChatListTile extends StatelessWidget {
  final AppUser user;
  final String chatId;
  final VoidCallback onTap;

  const _ChatListTile({
    required this.user,
    required this.chatId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chat = ChatService();

    return StreamBuilder<DocumentSnapshot>(
      stream: chat.chatDocStream(chatId),
      builder: (context, snap) {
        String lastMsg = 'Tap to chat';
        String timeText = '';

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          lastMsg = (data['lastMessage'] ?? 'Tap to chat').toString();
          final ts = data['lastMessageAt'];
          if (ts is Timestamp) timeText = _formatChatTime(ts);
        }

        final photoUrl = (user.photoUrl ?? '').trim();

        return ListTile(
          tileColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.purpleAccent.withOpacity(0.20),
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        // ✅ on light UI, use dark text inside avatar only if you want
                        // but usually white looks better on purpleAccent bg
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              // Online dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: user.online ? Colors.green : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 2),
                  ),
                ),
              ),
            ],
          ),

          // ✅ BLACK username
          title: Text(
            user.username,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),

          // ✅ Gray subtitle (Online or last message)
          subtitle: Text(
            user.online ? 'Online' : lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.subtext),
          ),

          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeText,
                style: const TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right, color: AppColors.subtext),
            ],
          ),
          onTap: onTap,
        );
      },
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
