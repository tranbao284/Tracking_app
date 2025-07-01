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
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.people_alt_rounded, color: Color(0xFFFFBCBC)),
            SizedBox(width: 8),
            Text('Danh sách bạn bè'),
          ],
        ),
        backgroundColor: const Color(0xFFB5EAEA),
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friendName = friends[index];
          return Card(
            color: const Color(0xFFE3FDFD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.cake, color: Color(0xFFFFBCBC)),
              title: Text(friendName),
              onTap: () {
                Navigator.pop(context, friendName);
              },
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB5EAEA)),
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFFFFF6F6),
    );
  }
}
