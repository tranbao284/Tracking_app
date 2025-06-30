import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _avatar;
  bool _isLoading = false;

  Future<void> _pickAvatar() async {
    setState(() { _isLoading = true; });
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatar = File(picked.path);
      });
    }
    setState(() { _isLoading = false; });
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) {
        final oldPass = TextEditingController();
        final newPass = TextEditingController();
        bool isDialogLoading = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('Đổi mật khẩu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPass,
                  decoration: InputDecoration(labelText: 'Mật khẩu cũ'),
                  obscureText: true,
                ),
                TextField(
                  controller: newPass,
                  decoration: InputDecoration(labelText: 'Mật khẩu mới'),
                  obscureText: true,
                ),
                if (isDialogLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isDialogLoading
                    ? null
                    : () async {
                        setStateDialog(() { isDialogLoading = true; });
                        await Future.delayed(Duration(seconds: 1)); // Giả lập loading
                        setStateDialog(() { isDialogLoading = false; });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã đổi mật khẩu (giả lập)')),
                        );
                      },
                child: Text('Đổi'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 400;
    return Scaffold(
      backgroundColor: Color(0xFFFFF5FD),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC1E3),
        title: Row(
          children: [
            Icon(Icons.person, color: Color(0xFFB5F8FE)),
            SizedBox(width: 8),
            Text('Hồ sơ Gen Z', style: TextStyle(fontFamily: 'BeVietnamPro')),
          ],
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Color(0xFFB5F8FE),
                        backgroundImage: _avatar != null
                            ? FileImage(_avatar!)
                            : null,
                        child: _avatar == null
                            ? Icon(Icons.person, size: 56, color: Color(0xFFFFC1E3))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFFFC1E3),
                            child: Icon(Icons.edit, color: Color(0xFFB5F8FE)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFC1E3),
                    foregroundColor: Color(0xFF7F6B8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _changePassword,
                  child: Text('Đổi mật khẩu 🔒'),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Color(0xFFFFC1E3).withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
} 