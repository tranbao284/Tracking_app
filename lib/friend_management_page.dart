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
          title: Row(
            children: const [
              Icon(Icons.group, color: Color(0xFFFFBCBC)),
              SizedBox(width: 8),
              Text('Quản lý bạn bè'),
            ],
          ),
          backgroundColor: const Color(0xFFB5EAEA),
          elevation: 0,
          centerTitle: false,
          bottom: const TabBar(
            indicatorColor: Color(0xFFFFBCBC),
            labelColor: Color(0xFF393E46),
            unselectedLabelColor: Color(0xFFB5EAEA),
            tabs: [
              Tab(icon: Icon(Icons.person_add_alt_1, color: Color(0xFFFFBCBC)), text: 'Gợi ý'),
              Tab(icon: Icon(Icons.mail, color: Color(0xFFFFBCBC)), text: 'Lời mời'),
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
            return Card(
              color: const Color(0xFFE3FDFD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFBCBC),
                  child: Text(userData['name']?[0] ?? 'U', style: const TextStyle(color: Color(0xFF393E46))),
                ),
                title: Text(userData['name'] ?? 'Người dùng mới'),
                subtitle: Text(userData['email'] ?? 'Không có email'),
                trailing: ElevatedButton.icon(
                  onPressed: () {
                    _firestoreService.sendFriendRequest(userDoc.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã gửi lời mời đến ${userData['name']}')),
                    );
                  },
                  icon: const Icon(Icons.favorite, color: Color(0xFFFFBCBC)),
                  label: const Text('Kết bạn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB5EAEA),
                    foregroundColor: Color(0xFF393E46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
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
                  color: const Color(0xFFE3FDFD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFBCBC),
                      child: Text(user['name']?[0] ?? 'U', style: const TextStyle(color: Color(0xFF393E46))),
                    ),
                    title: Text(user['name'] ?? 'Người dùng mới'),
                    subtitle: Text('${user['email']} muốn kết bạn với bạn.'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút chấp nhận
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Color(0xFFB5EAEA), size: 30),
                          onPressed: () => _firestoreService.acceptFriendRequest(userId),
                          tooltip: 'Chấp nhận',
                        ),
                        // Nút từ chối
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Color(0xFFFFBCBC), size: 30),
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
