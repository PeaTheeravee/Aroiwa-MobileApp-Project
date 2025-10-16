import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final Function(int) setPage;

  const LoginPage({super.key, required this.setPage});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _obscurePassword = true;

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // ตรวจสอบว่าแต่ละฟิลด์ถูกกรอกข้อมูลหรือไม่
    if (username.isEmpty && password.isEmpty) {
      setState(() {
        _errorMessage = 'Username and password cannot be empty.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Username cannot be empty.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Password cannot be empty.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        encoding: Encoding.getByName('utf-8'),
        body: {'username': username, 'password': password},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);

        // ตั้งค่า statelogin เป็น 'on'
        await prefs.setString('statelogin', 'on');

        //เมื่อ login จะเด้งไปหน้า profile_detail_page
        widget.setPage(2);
      } 
        // การเเจ้งเตือน เมื่อชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง
        else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Invalid username or password.';
        });
        await Future.delayed(Duration(seconds: 2));
        setState(() {
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = 'Unexpected error occurred. Please try again later.';
        });
        await Future.delayed(Duration(seconds: 2));
        setState(() {
          _errorMessage = '';
        });
      }
    } 
      // การเเจ้งเตือน เมื่อไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์
      catch (e) {
      setState(() {
        _errorMessage = 'Unable to connect to the internet. Please try later.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFCC80), // สีพื้นหลังตามภาพ
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/aroiwa-logo2.png',height: 150),
              const SizedBox(height: 35), 

              // TextField สำหรับ Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  fillColor: Colors.white, // ตั้งค่าสีพื้นหลังเป็นสีขาว
                  filled: true, // เปิดการใช้งานสีพื้นหลัง
                  prefixIcon: Icon(Icons.person,color: Colors.orange),
                ),
              ),
              const SizedBox(height: 15),

              // TextField สำหรับ Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.vpn_key, color: Colors.orange),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 35),

              // ปุ่ม Login
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 12.0,
                  ),
                ),
                child: const Text(
                  'login',
                  style: TextStyle(fontSize: 20,color: Colors.white),
                ),
              ),
              const SizedBox(height: 35),

              // ลิงก์สำหรับไปหน้า Register
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/register');
                },
                child: const Text(
                  'Don\'t have an account? Create account',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.brown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red,fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}