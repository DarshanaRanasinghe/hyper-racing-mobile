import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/app_user.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  static const routeName = '/chat-home';
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final _auth = AuthService();
  final _users = UserService();
  final _searchCtrl = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
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
          // Header + search + avatars
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

                // Search (username only)
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

                const SizedBox(height: 14),

                // Horizontal user avatars
                SizedBox(
                  height: 54,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _users.usersStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final docs = snap.data!.docs;

                      final users = docs
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
                        scrollDirection: Axis.horizontal,
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          return InkWell(
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
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white.withOpacity(0.18),
                              child: Text(
                                u.username.isNotEmpty
                                    ? u.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // User list (username only)
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

                final docs = snap.data!.docs;
                final users = docs
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

                    return ListTile(
                      tileColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.purpleAccent.withOpacity(
                          0.25,
                        ),
                        child: Text(
                          u.username.isNotEmpty
                              ? u.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        u.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Tap to chat',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
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
