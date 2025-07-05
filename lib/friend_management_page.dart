import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class FriendsManagementPage extends StatefulWidget {
  const FriendsManagementPage({super.key});

  @override
  State<FriendsManagementPage> createState() => _FriendsManagementPageState();
}

class _FriendsManagementPageState extends State<FriendsManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    // Sử dụng DefaultTabController để quản lý các tab
    return DefaultTabController(
      length: 2, // Có 2 tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý bạn bè'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_add_alt_1), text: 'Gợi ý'),
              Tab(icon: Icon(Icons.mail), text: 'Lời mời'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Nội dung cho Tab 1: Gợi ý kết bạn
            _buildSuggestionsTab(),
            // Nội dung cho Tab 2: Lời mời đã nhận
            _buildRequestsTab(),
          ],
        ),
      ),
    );
  }

  /// Widget xây dựng tab "Gợi ý"
  Widget _buildSuggestionsTab() {
    // Cần một hàm trong FirestoreService để lấy tất cả user
    // Ví dụ: _firestoreService.getAllUsersStream()
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không tìm thấy người dùng nào.'));
        }

        // Lọc ra người dùng hiện tại
        final allUsers = snapshot.data!.docs
            .where((doc) => doc.id != _currentUserId)
            .toList();

        if (allUsers.isEmpty) {
          return const Center(child: Text('Chưa có người dùng nào khác trong hệ thống.'));
        }

        return ListView.builder(
          itemCount: allUsers.length,
          itemBuilder: (context, index) {
            final userDoc = allUsers[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                // Có thể thêm ảnh đại diện ở đây
                child: Text(userData['name']?[0] ?? 'U'),
              ),
              title: Text(userData['name'] ?? 'Người dùng mới'),
              subtitle: Text(userData['email'] ?? 'Không có email'),
              trailing: ElevatedButton(
                onPressed: () {
                  _firestoreService.sendFriendRequest(userDoc.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã gửi lời mời đến ${userData['name']}')),
                  );
                },
                child: const Text('Kết bạn'),
              ),
            );
          },
        );
      },
    );
  }

  /// Widget xây dựng tab "Lời mời"
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Bạn không có lời mời kết bạn nào.'));
        }

        final requestDocs = snapshot.data!.docs;
        final requestUserIds = requestDocs.map((doc) => doc.id).toList();

        // Lấy thông tin chi tiết của những người gửi lời mời
        return FutureBuilder<List<DocumentSnapshot>>(
          future: _firestoreService.getUsersByIds(requestUserIds),
          builder: (context, userSnapshots) {
            if (!userSnapshots.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final requestUsers = userSnapshots.data!;
            return ListView.builder(
              itemCount: requestUsers.length,
              itemBuilder: (context, index) {
                final user = requestUsers[index].data() as Map<String, dynamic>;
                final userId = requestUsers[index].id;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user['name']?[0] ?? 'U'),
                    ),
                    title: Text(user['name'] ?? 'Người dùng mới'),
                    subtitle: Text('${user['email']} muốn kết bạn với bạn.'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút chấp nhận
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          onPressed: () => _firestoreService.acceptFriendRequest(userId),
                          tooltip: 'Chấp nhận',
                        ),
                        // Nút từ chối
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                          onPressed: () => _firestoreService.declineFriendRequest(userId),
                          tooltip: 'Từ chối',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
