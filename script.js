// Import Firebase SDK
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import {
  getFirestore,
  collection,
  addDoc,
  getDocs,
  query,
  where,
  doc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

// Firebase config của bạn
const firebaseConfig = {
  apiKey: "AIzaSyAqYc-nwdf_ScMpV44oEFVn9YYw0ZC6P1s",
  authDomain: "nhiemvunguoi4.firebaseapp.com",
  projectId: "nhiemvunguoi4",
  storageBucket: "nhiemvunguoi4.firebasestorage.app",
  messagingSenderId: "958889498374",
  appId: "1:958889498374:web:e3650d996c3505478c3087"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Gửi lời mời
async function sendRequest() {
  const from = document.getElementById("fromUser").value;
  const to = document.getElementById("toUser").value;
  if (!from || !to) return alert("Vui lòng nhập đủ thông tin!");

  const q = query(collection(db, "friend_requests"), where("from", "==", from), where("to", "==", to));
  const existing = await getDocs(q);
  if (!existing.empty) {
    alert("Lời mời đã tồn tại.");
    return;
  }

  await addDoc(collection(db, "friend_requests"), {
    from,
    to,
    status: "pending",
    createdAt: new Date()
  });
  alert("Đã gửi lời mời!");
  loadRequests();
}

// Hiển thị danh sách lời mời
async function loadRequests() {
  const list = document.getElementById("requestList");
  list.innerHTML = "";
  const snapshot = await getDocs(collection(db, "friend_requests"));
  snapshot.forEach(docSnap => {
    const data = docSnap.data();
    const li = document.createElement("li");
    li.innerHTML = `
      From: ${data.from} → To: ${data.to} - Status: ${data.status}
      ${data.status === "pending" ? `
        <button onclick="respond('${docSnap.id}', 'accepted')">✔️</button>
        <button onclick="respond('${docSnap.id}', 'rejected')">❌</button>
      ` : ""}
    `;
    list.appendChild(li);
  });
}

// Chấp nhận hoặc từ chối
async function respond(id, status) {
  await updateDoc(doc(db, "friend_requests", id), {
    status,
    respondedAt: new Date()
  });
  alert(`Đã ${status} lời mời.`);
  loadRequests();
}

window.sendRequest = sendRequest;
window.respond = respond;
window.onload = loadRequests;
