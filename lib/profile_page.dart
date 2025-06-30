import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
//import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
//import 'dart:typed_data';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  bool _showPasswordForm = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // User data
  String _name = 'Đang tải...';
  String _email = 'Đang tải...';
  String _phone = '';
  String _avatarUrl = 'https://res.cloudinary.com/drtdugxvl/image/upload/v1751299938/Screenshot_2025-06-30_231059_air3g9.png';
  String _uid = '';

  // Cloudinary config
  static const String _cloudName = 'drtdugxvl';
  static const String _apiKey = '684672377564572';
  static const String _uploadPreset = 'Tracking_app';

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
          _avatarUrl = data['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=3';
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

  Future<void> _uploadImage() async {
    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      final fileExtension = path.extension(image.path).replaceFirst('.', '');
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/upload');

      if (kIsWeb) {
        // ✅ Flutter Web xử lý upload qua FormData đúng cách
        final bytes = await image.readAsBytes();

        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final blob = html.Blob([bytes]);
        final file = html.File([blob], fileName); // ✅ Tạo File từ Blob có tên

        final formData = html.FormData();
        formData.appendBlob('file', file); // ✅ Append file đúng cách
        formData.append('upload_preset', _uploadPreset);
        formData.append('api_key', _apiKey);

        final response = await html.HttpRequest.request(
          uri.toString(),
          method: 'POST',
          sendData: formData,
        );

        if (response.status == 200) {
          final responseData = jsonDecode(response.responseText!);
          await _updateAvatarUrl(responseData['secure_url']);
        } else {
          throw Exception('Upload failed with status ${response.status}');
        }

      } else {
        // ✅ Mobile xử lý upload bằng MultipartRequest
        final mimeType = lookupMimeType(image.path);
        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = _uploadPreset
          ..fields['api_key'] = _apiKey
          ..files.add(await http.MultipartFile.fromPath(
            'file',
            image.path,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ));

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          await _updateAvatarUrl(jsonDecode(responseData)['secure_url']);
        } else {
          throw Exception('Upload failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi upload ảnh: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _updateAvatarUrl(String imageUrl) async {
    await _firestore.collection('users').doc(_uid).update({
      'avatarUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() => _avatarUrl = imageUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
    );
  }

  Future<void> _changePassword() async {
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
      // Reauthenticate
      final credential = EmailAuthProvider.credential(
        email: _email,
        password: _currentPasswordController.text,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // Verify phone
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final storedPhone = userDoc.data()?['phone']?.toString() ?? '';
      final inputPhone = _phoneController.text.trim();

      if (storedPhone.isEmpty) throw 'Tài khoản chưa đăng ký số điện thoại';
      if (_normalizePhone(storedPhone) != _normalizePhone(inputPhone)) {
        throw 'Số điện thoại không khớp';
      }

      // Update password
      await _auth.currentUser!.updatePassword(_newPasswordController.text.trim());

      // Update in Firestore
      await userDoc.reference.update({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công!')),
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

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('password');
      await prefs.setBool('is_logged_in', false);
      await _auth.signOut();

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
          SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')),
        );
      }
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password': return 'Mật khẩu hiện tại không đúng';
      case 'weak-password': return 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
      case 'requires-recent-login': return 'Yêu cầu đăng nhập lại';
      default: return 'Lỗi: ${e.message}';
    }
  }

  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

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
        body: Center(child: Text('Vui lòng đăng nhập')),
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(_avatarUrl),
                  backgroundColor: Colors.grey[200],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _isLoading ? null : _uploadImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

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

            if (_showPasswordForm) ...[
              const SizedBox(height: 30),
              const Text(
                'ĐỔI MẬT KHẨU',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword
                        ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    }),
                  ),
                ),
                obscureText: _obscureCurrentPassword,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại đã đăng ký',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword
                        ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    }),
                  ),
                ),
                obscureText: _obscureNewPassword,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu mới',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
              ),
              const SizedBox(height: 25),

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