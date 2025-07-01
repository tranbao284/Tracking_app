import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'friend_list_page.dart';
import 'pastel_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracking app',
      debugShowCheckedModeBanner: false,
      theme: pastelTheme,
      home: const AuthWrapper(),  // Đổi từ initialRoute sang home để check đăng nhập
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/friends': (context) => const FriendListScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Người dùng đã đăng nhập
        if (snapshot.hasData) {
          return const HomePage();
        }
        // Người dùng chưa đăng nhập
        return const LoginPage();
      },
    );
  }
}
