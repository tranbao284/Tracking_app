import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Điều hướng về trang đăng nhập khi đăng ký thành công

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signup() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // Sau khi đăng ký thành công, điều hướng về trang đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } catch (e) {
      print('Signup error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 400;
    final formPadding = isSmallScreen ? 12.0 : 24.0;
    final formFontSize = isSmallScreen ? 20.0 : 24.0;
    final iconSize = isSmallScreen ? 36.0 : 48.0;
    return Scaffold(
      backgroundColor: Color(0xFFFFF5FD),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC1E3),
        title: Row(
          children: [
            Icon(Icons.favorite, color: Color(0xFFB5F8FE)),
            SizedBox(width: 8),
            Text('Đăng ký Gen Z', style: TextStyle(fontFamily: 'BeVietnamPro')),
          ],
        ),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Container(
                padding: EdgeInsets.all(formPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFFC1E3).withOpacity(0.2),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: Color(0xFFFFC1E3), width: 1.2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1, size: iconSize, color: Color(0xFFFFC1E3)),
                    SizedBox(height: 12),
                    Text(
                      'Tạo tài khoản mới ✨',
                      style: TextStyle(
                        fontSize: formFontSize,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7F6B8A),
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email, color: Color(0xFFB5F8FE)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock, color: Color(0xFFFFC1E3)),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Color(0xFFFFC1E3),
                        ),
                        onPressed: signup,
                        child: Text('Đăng ký liền nè! 💖', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Color(0xFF7F6B8A), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
