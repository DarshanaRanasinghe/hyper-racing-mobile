import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'src/theme.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/chat_home_screen.dart';
import 'src/screens/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HyperRacingApp());
}

class HyperRacingApp extends StatelessWidget {
  const HyperRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;

    return MaterialApp(
      title: 'Hyper Racing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ✅ If user already logged in -> go to chat home
      // ✅ If not -> go to login
      initialRoute: loggedIn ? ChatHomeScreen.routeName : LoginScreen.routeName,

      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        ChatHomeScreen.routeName: (_) => const ChatHomeScreen(),
        ChatScreen.routeName: (_) => const ChatScreen(),
      },
    );
  }
}
