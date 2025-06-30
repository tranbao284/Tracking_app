// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'map_page.dart';
//import 'home_page.dart';
//import 'firebase_options.dart';
//import 'package:shared_preferences/shared_preferences.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC5_jqcFiypvHFr5mM43edwtgLsP0LgA8w",
      authDomain: "tracking-15c70.firebaseapp.com",
      projectId: "tracking-15c70",
      storageBucket: "tracking-15c70.appspot.com",
      messagingSenderId: "991610307749",
      appId: "1:991610307749:web:2652ec7e8f541affa0f94c",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tracking app',
      theme: ThemeData(
        fontFamily: 'BeVietnamPro',
        scaffoldBackgroundColor: const Color(0xFFFFF5FD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFC1E3),
          foregroundColor: Color(0xFF7F6B8A),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xff3AA6B9),
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            color: Color(0xff3AA6B9),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng nhập';
      if (e.code == 'user-not-found') {
        message = 'Tài khoản không tồn tại';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // void _login() {
  //   final email = _emailController.text.trim();
  //   final password = _passwordController.text;

  //   if (email != 'myuser') {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Email hoặc số điện thoại không đúng')),
  //     );
  //   } else if (password != '123456') {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Sai mật khẩu')),
  //     );
  //   } else {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => const HomeScreen()),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking your bestie')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ email hoặc số điện thoại',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff3AA6B9)),
                ),
                floatingLabelStyle: TextStyle(
                  color: Color(0xff3AA6B9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff3AA6B9)),
                ),
                floatingLabelStyle: TextStyle(
                  color: Color(0xff3AA6B9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff9bd3e0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEEEEEE)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(color: Color(0xFFFF9EAA)),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToRegister(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9EAA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEEEEEE)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: username,
          password: password,
        );
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đăng ký thành công, hãy đăng nhập nhé!')),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Đăng ký thất bại';
        if (e.code == 'email-already-in-use') {
          message = 'Email đã được sử dụng';
        } else if (e.code == 'invalid-email') {
          message = 'Email không hợp lệ';
        } else if (e.code == 'weak-password') {
          message = 'Mật khẩu quá yếu';
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Vui lòng nhập email';
                  if (value.length < 6) return 'Email phải có ít nhất 6 ký tự';
                  return null;
                },
                onSaved: (value) => username = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Vui lòng nhập mật khẩu';
                  if (value.length < 6)
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
                onSaved: (value) => password = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String fullName = '';
//   String username = '';
//   String password = '';
//   bool isUsernameTaken = false;

//   void _submit() {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//       setState(() {
//         isUsernameTaken = username.toLowerCase() == 'admin';
//       });
//       if (!isUsernameTaken) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Đăng ký thành công, hãy đăng nhập nhé!')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Thông tin đăng ký')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 decoration: const InputDecoration(labelText: 'Tên người dùng'),
//                 maxLength: 20,
//                 onSaved: (value) => fullName = value ?? '',
//                 validator: (value) =>
//                     value == null || value.isEmpty ? 'Nhập tên' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Địa chỉ email hoặc số điện thoại',
//                   errorText: isUsernameTaken
//                       ? 'Địa chỉ email hoặc số điện thoại đã tồn tại'
//                       : null,
//                 ),
//                 maxLength: 30,
//                 onChanged: (value) {
//                   setState(() {
//                     username = value;
//                     isUsernameTaken = false;
//                   });
//                 },
//                 onSaved: (value) => username = value ?? '',
//                 validator: (value) => value == null || value.isEmpty
//                     ? 'Nhập tên đăng nhập'
//                     : null,
//               ),
//               TextFormField(
//                 decoration: const InputDecoration(labelText: 'Mật khẩu'),
//                 obscureText: true,
//                 onSaved: (value) => password = value ?? '',
//                 validator: (value) => value == null || value.length < 6
//                     ? 'Mật khẩu ít nhất 6 ký tự'
//                     : null,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _submit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFFF9EAA),
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Đăng ký'),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friends = ['My', 'Ngoc', 'Huy', 'Linh'];

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách bạn bè')),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(friends[index]),
            onTap: () {
              Navigator.pop(context, friends[index]); // giả lập chọn
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool canEdit = false;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  void _verifyPasswordAndEnableEdit() {
    if (_currentPasswordController.text == '123456') {
      setState(() {
        canEdit = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực thành công, bạn có thể thay đổi thông tin.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sai mật khẩu hiện tại!'),
        ),
      );
    }
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thông tin đã được cập nhật!')),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            if (!canEdit) ...[
              const Text('Nhập mật khẩu để thay đổi thông tin:'),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _verifyPasswordAndEnableEdit,
                child: const Text('Xác thực'),
              ),
            ] else ...[
              const Text('Thay đổi thông tin cá nhân:'),
              TextField(
                controller: _displayNameController,
                decoration:
                    const InputDecoration(labelText: 'Tên hiển thị mới'),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Lưu thay đổi'),
              ),
            ],
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: const Text('Đăng xuất'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
