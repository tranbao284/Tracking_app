import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Nếu chưa đăng nhập thì báo lỗi
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không tìm thấy thông tin người dùng.'),
        ),
      );
    }

    // Lấy thông tin người dùng
    final String name = user.displayName ?? 'Không có tên';
    final String email = user.email ?? 'Không có email';
    final String avatarUrl = user.photoURL ?? 'https://i.pravatar.cc/150?img=3';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}
