// Import Firebase
import { initializeApp } from "firebase/app";
import {
  getFirestore,
  collection,
  addDoc,
  getDocs,
  query,
  where,
  doc,
  updateDoc
} from "firebase/firestore";

// Cấu hình Firebase của bạn
const firebaseConfig = {
  apiKey: "AIzaSyAqYc-nwdf_ScMpV44oEFVn9YYw0ZC6P1s",
  authDomain: "nhiemvunguoi4.firebaseapp.com",
  projectId: "nhiemvunguoi4",
  storageBucket: "nhiemvunguoi4.firebasestorage.app",
  messagingSenderId: "958889498374",
  appId: "1:958889498374:web:e3650d996c3505478c3087"
};

// Khởi tạo Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Gửi lời mời kết bạn (có kiểm tra trùng)
async function sendFriendRequest(fromUserId, toUserId) {
  try {
    const q = query(
      collection(db, "friend_requests"),
      where("from", "==", fromUserId),
      where("to", "==", toUserId)
    );
    const existing = await getDocs(q);
    if (!existing.empty) {
      console.log("Lời mời đã tồn tại, không gửi lại.");
      return;
    }

    const docRef = await addDoc(collection(db, "friend_requests"), {
      from: fromUserId,
      to: toUserId,
      status: "pending",
      createdAt: new Date()
    });
    console.log("Lời mời đã gửi với ID:", docRef.id);
  } catch (e) {
    console.error("Lỗi gửi lời mời:", e);
  }
}

// Lấy tất cả lời mời kết bạn
async function getFriendRequests() {
  const querySnapshot = await getDocs(collection(db, "friend_requests"));
  querySnapshot.forEach((doc) => {
    console.log(doc.id, "=>", doc.data());
  });
}

// Chấp nhận hoặc từ chối lời mời
async function respondToFriendRequest(requestId, newStatus) {
  try {
    const requestRef = doc(db, "friend_requests", requestId);
    await updateDoc(requestRef, {
      status: newStatus,
      respondedAt: new Date()
    });
    console.log(`Lời mời ${requestId} đã được ${newStatus}`);
  } catch (e) {
    console.error("Lỗi cập nhật lời mời:", e);
  }
}

// Gọi thử:
await sendFriendRequest("user1", "user2"); // Gửi lời mời
await getFriendRequests(); // Xem danh sách
// await respondToFriendRequest("abc123", "accepted"); // Test nếu có ID cụ thể
