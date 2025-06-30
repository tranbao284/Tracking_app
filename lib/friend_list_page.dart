// File: lib/friend_list_page.dart
import 'package:flutter/material.dart';
import 'map_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<String> friends = [
    'Ngoc',
    'Huy',
    // Bạn có thể thêm tên bạn bè ở đây
  ];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedFriends = prefs.getStringList('friends');
    if (savedFriends != null && savedFriends.isNotEmpty) {
      setState(() {
        friends = savedFriends;
      });
    }
  }

  Future<void> _saveFriends() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('friends', friends);
  }

  void _addFriend(String name) {
    setState(() {
      friends.add(name);
    });
    _saveFriends();
  }

  void _showAddFriendDialog() {
    String newFriend = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm bạn mới'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: 'Nhập tên bạn'),
          onChanged: (value) => newFriend = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newFriend.trim().isNotEmpty) {
                _addFriend(newFriend.trim());
                Navigator.pop(context);
              }
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(friendToFocus: friendName)),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: Color(0xFFFFC1E3),
        child: Icon(Icons.person_add, color: Color(0xFFB5F8FE)),
        tooltip: 'Thêm bạn',
      ),
    );
  }
}
