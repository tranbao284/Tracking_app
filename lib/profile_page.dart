import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers cho form đổi mật khẩu
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Biến trạng thái
  bool _isLoading = true;
  String? _errorMessage;
  bool _showPasswordForm = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Thông tin người dùng
  String _name = 'Đang tải...';
  String _email = 'Đang tải...';
  String _phone = '';
  String _avatarUrl = 'https://i.pravatar.cc/150?img=3';
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Tải thông tin người dùng từ Firestore
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
          _uid = user.uid;
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

  // Đổi mật khẩu
  Future<void> _changePassword() async {
    // Validate input
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng điền đầy đủ thông tin');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Mật khẩu mới không khớp');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // 1. Xác thực mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: _email,
        password: _currentPasswordController.text,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // 2. Kiểm tra số điện thoại trong Firestore
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final storedPhone = userDoc.data()?['phone']?.toString() ?? '';
      final inputPhone = _phoneController.text.trim();

      if (storedPhone.isEmpty) {
        throw 'Tài khoản chưa đăng ký số điện thoại';
      }

      if (_normalizePhone(storedPhone) != _normalizePhone(inputPhone)) {
        throw 'Số điện thoại không khớp với thông tin đăng ký';
      }

      // 3. Cập nhật mật khẩu mới
      await _auth.currentUser!.updatePassword(_newPasswordController.text.trim());

      // 4. Cập nhật thời gian đổi mật khẩu trong Firestore
      await userDoc.reference.update({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Thông báo thành công và reset form
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _showPasswordForm = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getAuthErrorMessage(e));
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Đăng xuất
  Future<void> _logout() async {
    try {
      // Xóa thông tin remember me
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('password');
      await prefs.setBool('is_logged_in', false);

      // Đăng xuất khỏi Firebase
      await _auth.signOut();

      // Điều hướng về trang đăng nhập và xóa stack
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

  // Helper methods
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Mật khẩu hiện tại không đúng';
      case 'weak-password':
        return 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
      case 'requires-recent-login':
        return 'Yêu cầu đăng nhập lại để thực hiện thao tác này';
      default:
        return 'Lỗi: ${e.message}';
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

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
          child: Text('Vui lòng đăng nhập để xem thông tin cá nhân'),
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Phần thông tin cá nhân
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(_avatarUrl),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 20),
            Text(
              _name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // Nút chức năng
            if (!_showPasswordForm) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Đổi mật khẩu'),
                  onPressed: () {
                    setState(() {
                      _showPasswordForm = true;
                      _errorMessage = null;
                      _phoneController.text = _phone;
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  onPressed: _logout,
                ),
              ),
            ],

            // Form đổi mật khẩu
            if (_showPasswordForm) ...[
              const SizedBox(height: 30),
              const Text(
                'ĐỔI MẬT KHẨU',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),

              // Mật khẩu hiện tại
              TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    }),
                  ),
                ),
                obscureText: _obscureCurrentPassword,
              ),
              const SizedBox(height: 15),

              // // Số điện thoại
              // TextField(
              //   controller: _phoneController,
              //   decoration: const InputDecoration(
              //     labelText: 'Số điện thoại đã đăng ký',
              //     border: OutlineInputBorder(),
              //     prefixIcon: Icon(Icons.phone),
              //   ),
              //   keyboardType: TextInputType.phone,
              // ),
              // const SizedBox(height: 15),

              // Mật khẩu mới
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    }),
                  ),
                ),
                obscureText: _obscureNewPassword,
              ),
              const SizedBox(height: 15),

              // Xác nhận mật khẩu mới
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu mới',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
              ),
              const SizedBox(height: 25),

              // Nút xác nhận và hủy
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('XÁC NHẬN'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showPasswordForm = false;
                          _errorMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('HỦY'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}