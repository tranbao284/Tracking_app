import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'friend_list_page.dart';
import 'map_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF5FD),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC1E3),
        title: Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFB5F8FE)),
            SizedBox(width: 8),
            Text('Xin chào Gen Z! 🦄', style: TextStyle(fontFamily: 'BeVietnamPro')),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Color(0xFFB5F8FE)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFFB5F8FE)),
            onPressed: () => logout(context),
          ),
        ],
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                Text(
                  'Chào mừng bạn đến với Tracking App! 💖',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7F6B8A),
                    fontFamily: 'BeVietnamPro',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Card(
                  color: Color(0xFFB5F8FE),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: ListTile(
                    leading: Icon(Icons.people, color: Color(0xFFFFC1E3)),
                    title: Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Kết nối bạn bè siêu tốc 🚀'),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFFFFC1E3)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FriendListScreen()),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  color: Color(0xFFFFC1E3),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: ListTile(
                    leading: Icon(Icons.map, color: Color(0xFFB5F8FE)),
                    title: Text('Bản đồ', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Xem vị trí bạn bè trên map 🗺️'),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFFB5F8FE)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HomeScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
