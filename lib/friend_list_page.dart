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
        title: const Text('Danh sách bạn bè'),
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friendName = friends[index];
          return ListTile(
            title: Text(friendName),
            onTap: () {
              Navigator.pop(context, friendName);
            },
          );
        },
      ),
    );
  }
}
