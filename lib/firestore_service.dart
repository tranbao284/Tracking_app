import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart'; // Cần cho việc cập nhật vị trí

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy thông tin người dùng đang đăng nhập
  User? get currentUser => _auth.currentUser;

  // --- Quản lý thông tin User ---

  /// Lưu thông tin người dùng khi họ đăng ký
  /// hoặc cập nhật thông tin khi cần.
  Future<void> saveUser(User user, {String? displayName}) async {
    final userRef = _db.collection('users').doc(user.uid);
    // Dùng SetOptions(merge: true) để không ghi đè dữ liệu hiện có (như vị trí)
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName ?? user.displayName ?? user.email?.split('@')[0],
    }, SetOptions(merge: true));
  }

  /// Cập nhật vị trí của người dùng hiện tại.
  Future<void> updateUserLocation(LatLng location) async {
    if (currentUser == null) return;
    await _db.collection('users').doc(currentUser!.uid).update({
      'location': GeoPoint(location.latitude, location.longitude),
    });
  }

  /// Lấy stream của tất cả người dùng (trừ người dùng hiện tại).
  /// Dùng cho tab "Gợi ý".
  Stream<QuerySnapshot> getAllUsersStream() {
    return _db.collection('users').snapshots();
  }


  // --- Quản lý Bạn bè & Lời mời ---

  /// Gửi lời mời kết bạn từ người dùng hiện tại đến receiverId.
  Future<void> sendFriendRequest(String receiverId) async {
    if (currentUser == null || currentUser!.uid == receiverId) return;

    final senderId = currentUser!.uid;

    // Ghi vào sub-collection của người gửi
    await _db
        .collection('users')
        .doc(senderId)
        .collection('friendRequestsSent')
        .doc(receiverId)
        .set({'status': 'pending', 'timestamp': FieldValue.serverTimestamp()});

    // Ghi vào sub-collection của người nhận
    await _db
        .collection('users')
        .doc(receiverId)
        .collection('friendRequestsReceived')
        .doc(senderId)
        .set({'status': 'pending', 'timestamp': FieldValue.serverTimestamp()});
  }

  /// Chấp nhận lời mời kết bạn từ senderId.
  Future<void> acceptFriendRequest(String senderId) async {
    if (currentUser == null) return;
    final receiverId = currentUser!.uid;

    final now = Timestamp.now();

    // Thêm vào danh sách bạn bè của cả hai người
    await _db.collection('users').doc(receiverId).collection('friends').doc(senderId).set({'friendSince': now});
    await _db.collection('users').doc(senderId).collection('friends').doc(receiverId).set({'friendSince': now});

    // Xóa lời mời ở cả hai phía để dọn dẹp
    await _db.collection('users').doc(receiverId).collection('friendRequestsReceived').doc(senderId).delete();
    await _db.collection('users').doc(senderId).collection('friendRequestsSent').doc(receiverId).delete();
  }

  /// Từ chối/Hủy lời mời kết bạn từ senderId.
  Future<void> declineFriendRequest(String senderId) async {
    if (currentUser == null) return;
    final receiverId = currentUser!.uid;

    // Xóa lời mời ở cả hai phía
    await _db.collection('users').doc(receiverId).collection('friendRequestsReceived').doc(senderId).delete();
    await _db.collection('users').doc(senderId).collection('friendRequestsSent').doc(receiverId).delete();
  }

  /// Lấy stream các lời mời kết bạn đã nhận.
  Stream<QuerySnapshot> getFriendRequestsStream() {
    if (currentUser == null) return const Stream.empty();
    return _db.collection('users').doc(currentUser!.uid).collection('friendRequestsReceived').snapshots();
  }
  /// Lấy stream danh sách bạn bè.
  Stream<QuerySnapshot> getFriendsStream() {
    if (currentUser == null) return const Stream.empty();
    // Lắng nghe sự thay đổi trong sub-collection 'friends' của người dùng hiện tại
    return _db.collection('users').doc(currentUser!.uid).collection('friends').snapshots();
  }

  /// Lấy thông tin chi tiết của một danh sách người dùng dựa trên ID của họ.
  /// Rất hữu ích để hiển thị thông tin của người gửi lời mời.
  Future<List<DocumentSnapshot>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final snapshots = await _db.collection('users').where(FieldPath.documentId, whereIn: userIds).get();
    return snapshots.docs;
  }
}
