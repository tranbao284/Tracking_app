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

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Set<String> _friendIds = {};
  Set<String> _sentRequestIds = {};
  Set<String> _receivedRequestIds = {};
  int _receivedRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFriendIds();
    _loadSentRequests();
    _loadReceivedRequests();
  }

  Future<void> _loadFriendIds() async {
    if (_currentUserId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .get();

    setState(() {
      _friendIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _loadSentRequests() async {
    if (_currentUserId == null) return;
    final sent = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('friendRequestsSent')
        .get();

    setState(() {
      _sentRequestIds = sent.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _loadReceivedRequests() async {
    if (_currentUserId == null) return;
    final received = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('friendRequestsReceived')
        .get();

    setState(() {
      _receivedRequestIds = received.docs.map((doc) => doc.id).toSet();
      _receivedRequestCount = received.size;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý bạn bè'),
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.person_add_alt_1), text: 'Gợi ý'),
              Tab(
                icon: const Icon(Icons.mail),
                text: 'Lời mời${_receivedRequestCount > 0 ? ' (${_receivedRequestCount})' : ''}',
              ),
              const Tab(icon: Icon(Icons.group), text: 'Đã kết bạn'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSuggestionsTab(),
            _buildRequestsTab(),
            _buildFriendsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm người dùng...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase().trim();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Không tìm thấy người dùng nào.'));
              }

              final allUsers = snapshot.data!.docs.where((doc) {
                final otherUserId = doc.id;
                final data = doc.data() as Map<String, dynamic>;

                if (otherUserId == _currentUserId) return false;
                if (_friendIds.contains(otherUserId)) return false;
                if (_sentRequestIds.contains(otherUserId)) return false;
                if (_receivedRequestIds.contains(otherUserId)) return false;

                final name = data['name']?.toLowerCase() ?? '';
                final email = data['email']?.toLowerCase() ?? '';
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              if (allUsers.isEmpty) {
                return const Center(child: Text('Không tìm thấy người dùng phù hợp.'));
              }

              return ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final userDoc = allUsers[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final otherUserId = userDoc.id;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(userData['name']?[0] ?? 'U'),
                    ),
                    title: Text(userData['name'] ?? 'Người dùng mới'),
                    subtitle: Text(userData['email'] ?? 'Không có email'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _firestoreService.sendFriendRequest(otherUserId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã gửi lời mời đến ${userData['name']}')),
                        );
                        _loadSentRequests();
                      },
                      child: const Text('Kết bạn'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

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
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          onPressed: () {
                            _firestoreService.acceptFriendRequest(userId);
                            _loadFriendIds();
                            _loadReceivedRequests();
                          },
                          tooltip: 'Chấp nhận',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                          onPressed: () {
                            _firestoreService.declineFriendRequest(userId);
                            _loadReceivedRequests();
                          },
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

  Widget _buildFriendsTab() {
    if (_currentUserId == null) {
      return const Center(child: Text('Không xác định người dùng.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Bạn chưa có bạn bè nào.'));
        }

        final friendDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: friendDocs.length,
          itemBuilder: (context, index) {
            final friendDoc = friendDocs[index];
            final friendId = friendDoc.id;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data!.data() as Map<String, dynamic>?;

                if (data == null) return const SizedBox.shrink();

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(data['name']?[0] ?? 'U'),
                  ),
                  title: Text(data['name'] ?? 'Người dùng'),
                  subtitle: Text(data['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove),
                    tooltip: 'Hủy kết bạn',
                    onPressed: () {
                      _firestoreService.removeFriend(friendId);
                      _loadFriendIds();
                    },
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
