import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; // Import trang đăng nhập

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  bool _showPasswordForm = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String _name = 'Đang tải...';
  String _email = 'Đang tải...';
  String _phone = '';
  String _avatarUrl = 'https://i.pravatar.cc/150?img=3';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _name = data['name'] ?? 'Không có tên';
          _email = user.email ?? 'Không có email';
          _phone = data['phone']?.toString() ?? '';
          _avatarUrl = user.photoURL ?? 'https://i.pravatar.cc/150?img=3';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải thông tin người dùng';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Điều hướng về trang đăng nhập và xóa stack navigation
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: ${e.toString()}')),
        );
      }
    }
  }

  // ... (giữ nguyên các phương thức _changePassword, _getAuthErrorMessage, _normalizePhone)

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không tìm thấy thông tin người dùng.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_avatarUrl),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 24),
              Text(
                _name,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _email,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              if (!_showPasswordForm)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showPasswordForm = true;
                          _errorMessage = null;
                          _phoneController.text = _phone;
                        });
                      },
                      child: const Text('Đổi mật khẩu'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),

              if (_showPasswordForm) ...[
                // ... (giữ nguyên phần form đổi mật khẩu)
              ],
            ],
          ),
        ),
      ),
    );
  }
}