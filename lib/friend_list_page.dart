// File: lib/friend_list_page.dart
import 'package:flutter/material.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  final List<String> friends = const [
    'Ngoc',
    'Huy',
    // Bạn có thể thêm tên bạn bè ở đây
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC1E3),
        title: Row(
          children: [
            const Icon(Icons.people, color: Color(0xFFB5F8FE)),
            SizedBox(width: 8),
            const Text('Danh sách bạn bè', style: TextStyle(fontFamily: 'BeVietnamPro')),
          ],
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: friends.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final friendName = friends[index];
            return Card(
              color: const Color(0xFFB5F8FE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                title: Text(
                  friendName,
                  style: const TextStyle(
                    color: Color(0xFF7F6B8A),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFC1E3)),
                onTap: () {
                  Navigator.pop(context, friendName);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
