import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendSuggestionsPage extends StatefulWidget {
  const FriendSuggestionsPage({super.key});

  @override
  State<FriendSuggestionsPage> createState() => _FriendSuggestionsPageState();
}

class _FriendSuggestionsPageState extends State<FriendSuggestionsPage> {
  late final String currentUid;
  late Future<List<DocumentSnapshot>> futureSuggestedUsers;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
    futureSuggestedUsers = _getSuggestedUsers();
  }

  Future<List<DocumentSnapshot>> _getSuggestedUsers() async {
    final allUsersSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    final friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .get();

    final sentRequestsSnapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: currentUid)
        .get();

    final receivedRequestsSnapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: currentUid)
        .get();

    final excludedUids = <String>{};
    excludedUids.add(currentUid);
    excludedUids.addAll(friendsSnapshot.docs.map((doc) => doc.id));
    excludedUids.addAll(
        sentRequestsSnapshot.docs.map((doc) => doc['to'] as String));
    excludedUids.addAll(
        receivedRequestsSnapshot.docs.map((doc) => doc['from'] as String));

    return allUsersSnapshot.docs
        .where((doc) => !excludedUids.contains(doc.id))
        .toList();
  }

  Future<void> _sendFriendRequest(String toUid) async {
    await FirebaseFirestore.instance.collection('friend_requests').add({
      'from': currentUid,
      'to': toUid,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi lời mời kết bạn.')),
    );

    setState(() {
      futureSuggestedUsers = _getSuggestedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý kết bạn')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: futureSuggestedUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có gợi ý nào.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name'];
              final email = user['email'];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                title: Text(name),
                subtitle: Text(email),
                trailing: TextButton(
                  onPressed: () => _sendFriendRequest(user.id),
                  child: const Text('Kết bạn'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
