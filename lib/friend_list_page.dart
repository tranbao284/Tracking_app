import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý bạn bè'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: 'Gợi ý'),
              Tab(icon: Icon(Icons.mail), text: 'Lời mời'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SuggestedFriendsTab(),
            FriendRequestsTab(),
          ],
        ),
      ),
    );
  }
}

// =================== TAB GỢI Ý =====================

class SuggestedFriendsTab extends StatefulWidget {
  const SuggestedFriendsTab({super.key});

  @override
  State<SuggestedFriendsTab> createState() => _SuggestedFriendsTabState();
}

class _SuggestedFriendsTabState extends State<SuggestedFriendsTab> {
  late final String currentUid;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<List<DocumentSnapshot>> _getSuggestedUsers() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    final friends = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .get();
    final sent = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: currentUid)
        .get();
    final received = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: currentUid)
        .get();
    final blocked = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('blocked')
        .get();

    final excluded = <String>{
      currentUid,
      ...friends.docs.map((doc) => doc.id),
      ...sent.docs.map((doc) => doc['to']),
      ...received.docs.map((doc) => doc['from']),
      ...blocked.docs.map((doc) => doc.id),
    };

    return users.docs.where((doc) => !excluded.contains(doc.id)).toList();
  }

  Future<void> _sendRequest(String toUid) async {
    await FirebaseFirestore.instance.collection('friend_requests').add({
      'from': currentUid,
      'to': toUid,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi lời mời kết bạn!')),
    );

    setState(() {});
  }

  Future<void> _blockUser(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('blocked')
        .doc(uid)
        .set({});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chặn người dùng')),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getSuggestedUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        if (users.isEmpty) return const Center(child: Text('Không có gợi ý'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final name = doc['name'];
            final email = doc['email'];

            return ListTile(
              leading: CircleAvatar(child: Text(name[0].toUpperCase())),
              title: Text(name),
              subtitle: Text(email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _sendRequest(doc.id),
                    child: const Text('Kết bạn'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _blockUser(doc.id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Chặn'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// =================== TAB LỜI MỜI =====================

class FriendRequestsTab extends StatelessWidget {
  const FriendRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('to', isEqualTo: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) return const Center(child: Text('Không có lời mời'));

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final fromUid = doc['from'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const ListTile(title: Text('...'));
                final user = userSnap.data!;
                final name = user['name'];
                final email = user['email'];

                return ListTile(
                  leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUid)
                          .collection('friends')
                          .doc(fromUid)
                          .set({});
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(fromUid)
                          .collection('friends')
                          .doc(currentUid)
                          .set({});
                      await FirebaseFirestore.instance
                          .collection('friend_requests')
                          .doc(doc.id)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chấp nhận kết bạn')),
                      );
                    },
                    child: const Text('Chấp nhận'),
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

