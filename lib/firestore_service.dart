import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===== Thông tin người dùng hiện tại =====
  User? get currentUser => _auth.currentUser;

  // ===== Lưu thông tin người dùng khi đăng ký =====
  Future<void> saveUser(User user, {String? displayName}) async {
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName':
      displayName ?? user.displayName ?? user.email?.split('@')[0],
    }, SetOptions(merge: true));
  }

  // ===== Cập nhật vị trí người dùng =====
  Future<void> updateUserLocation(LatLng location) async {
    if (currentUser == null) return;
    await _db.collection('users').doc(currentUser!.uid).update({
      'location': GeoPoint(location.latitude, location.longitude),
    });
  }

  // ===== Stream tất cả người dùng (dùng cho gợi ý) =====
  Stream<QuerySnapshot> getAllUsersStream() =>
      _db.collection('users').snapshots();

  // ===== Gửi lời mời kết bạn =====
  Future<void> sendFriendRequest(String receiverId) async {
    if (currentUser == null || currentUser!.uid == receiverId) return;

    final senderId = currentUser!.uid;

    // Người gửi
    await _db
        .collection('users')
        .doc(senderId)
        .collection('friendRequestsSent')
        .doc(receiverId)
        .set({'status': 'pending', 'timestamp': FieldValue.serverTimestamp()});

    // Người nhận
    await _db
        .collection('users')
        .doc(receiverId)
        .collection('friendRequestsReceived')
        .doc(senderId)
        .set({'status': 'pending', 'timestamp': FieldValue.serverTimestamp()});
  }

  // ===== Chấp nhận lời mời kết bạn =====
  Future<void> acceptFriendRequest(String senderId) async {
    if (currentUser == null) return;

    final receiverId = currentUser!.uid;
    final now = Timestamp.now();

    // Thêm bạn bè 2 chiều
    await _db
        .collection('users')
        .doc(receiverId)
        .collection('friends')
        .doc(senderId)
        .set({'friendSince': now});

    await _db
        .collection('users')
        .doc(senderId)
        .collection('friends')
        .doc(receiverId)
        .set({'friendSince': now});

    // Xoá lời mời ở cả hai phía
    await _db
        .collection('users')
        .doc(receiverId)
        .collection('friendRequestsReceived')
        .doc(senderId)
        .delete();

    await _db
        .collection('users')
        .doc(senderId)
        .collection('friendRequestsSent')
        .doc(receiverId)
        .delete();
  }

  // ===== Từ chối lời mời kết bạn =====
  Future<void> declineFriendRequest(String senderId) async {
    if (currentUser == null) return;
    final receiverId = currentUser!.uid;

    await _db
        .collection('users')
        .doc(receiverId)
        .collection('friendRequestsReceived')
        .doc(senderId)
        .delete();

    await _db
        .collection('users')
        .doc(senderId)
        .collection('friendRequestsSent')
        .doc(receiverId)
        .delete();
  }

  // ===== Hủy kết bạn =====
  Future<void> removeFriend(String friendId) async {
    if (currentUser == null) return;

    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .doc(friendId)
        .delete();

    await _db
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUser!.uid)
        .delete();
  }

  // ===== Stream lời mời kết bạn đã nhận =====
  Stream<QuerySnapshot> getFriendRequestsStream() {
    if (currentUser == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friendRequestsReceived')
        .snapshots();
  }

  // ===== Stream danh sách bạn bè =====
  Stream<QuerySnapshot> getFriendsStream() {
    if (currentUser == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('friends')
        .snapshots();
  }

  // ===== Lấy thông tin người dùng theo danh sách UID =====
  Future<List<DocumentSnapshot>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final snapshots = await _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();
    return snapshots.docs;
  }
}
