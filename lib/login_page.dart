import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (isLoggedIn && savedEmail != null && savedPassword != null) {
      try {
        setState(() => _isLoading = true);
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: savedEmail,
          password: savedPassword,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } catch (e) {
        await prefs.remove('password');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      _emailController.text = savedEmail ?? '';
      _passwordController.text = savedPassword ?? '';
      _rememberMe = savedPassword != null;
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('email', _emailController.text.trim());

      if (_rememberMe) {
        await prefs.setString('password', _passwordController.text.trim());
      } else {
        await prefs.remove('password');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getAuthErrorMessage(e));
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi hệ thống: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      default:
        return 'Đăng nhập thất bại: ${e.message}';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background ảnh mạng pastel
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?fit=crop&w=800&q=80',
              fit: BoxFit.cover,
              color: Colors.white.withOpacity(0.7),
              colorBlendMode: BlendMode.lighten,
            ),
          ),
          // Form đăng nhập nổi ở giữa
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_emotions, color: Color(0xFFFFBCBC), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Chào mừng Gen Z quay lại! ✨',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF393E46),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF6F6),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        TextField(
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
        ),
        const SizedBox(height: 16),
        TextField(
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
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: const Color(0xFFB5EAEA)),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
        ),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) => setState(() => _rememberMe = value ?? false),
              activeColor: const Color(0xFFFFBCBC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            const Text('Ghi nhớ mật khẩu'),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _login,
            icon: const Icon(Icons.login, color: Color(0xFFFFBCBC)),
            label: const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFBCBC),
              foregroundColor: Color(0xFF393E46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpPage()),
            );
          },
          child: const Text(
            'Chưa có tài khoản? Đăng ký liền nè! 🥰',
            style: TextStyle(color: Color(0xFFFFBCBC)),
          ),
        ),
      ],
    );
  }
}