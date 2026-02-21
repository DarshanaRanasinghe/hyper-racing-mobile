import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/theme.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HyperRacingApp());
}

class HyperRacingApp extends StatelessWidget {
  const HyperRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyper Racing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
      },
    );
  }
}
