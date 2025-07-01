import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // 1. Tạo tài khoản với Firebase Authentication
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // 2. Lưu thông tin bổ sung vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid, // Lưu cả UID để tiện truy vấn sau này
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Cập nhật trạng thái đăng nhập trong SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_uid', user.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!'),
              backgroundColor: Colors.green,
            ),
          );

          // Chuyển thẳng đến trang chủ sau khi đăng ký
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại';
      if (e.code == 'email-already-in-use') {
        message = 'Email này đã được đăng ký';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu phải có ít nhất 6 ký tự';
      }
      setState(() => _errorMessage = message);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi hệ thống: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.emoji_emotions_outlined, color: Color(0xFFFFBCBC)),
            SizedBox(width: 8),
            Text('Đăng ký tài khoản'),
          ],
        ),
        backgroundColor: const Color(0xFFB5EAEA),
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFB5EAEA)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE3FDFD),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFFFFBCBC)),
                  suffixIcon: const Icon(Icons.favorite, color: Color(0xFFFFE2E2)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFB5EAEA)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE3FDFD),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFFFFBCBC)),
                  suffixIcon: const Icon(Icons.star_rounded, color: Color(0xFFFFE2E2)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFB5EAEA)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE3FDFD),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFBCBC)),
                  suffixIcon: const Icon(Icons.cake, color: Color(0xFFFFE2E2)),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu';
                  if (value!.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFB5EAEA)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFE3FDFD),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFBCBC)),
                  suffixIcon: const Icon(Icons.icecream, color: Color(0xFFFFE2E2)),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số điện thoại';
                  if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                    return 'Số điện thoại phải có 10 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _signUp,
                  icon: const Icon(Icons.rocket_launch, color: Color(0xFFFFBCBC)),
                  label: const Text(
                    'ĐĂNG KÝ',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB5EAEA),
                    foregroundColor: Color(0xFF393E46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}