import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegExp.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final lengthCheck = password.length >= 8;
    final uppercaseCheck = RegExp(r'[A-Z]').hasMatch(password);
    final lowercaseCheck = RegExp(r'[a-z]').hasMatch(password);
    final specialCharCheck = RegExp(r'[!@#$%^&*(),.?":{}|<>+-]').hasMatch(password);
    return lengthCheck && uppercaseCheck && lowercaseCheck && specialCharCheck;
  }

  bool _areFieldsFilled() {
    return _emailController.text.isNotEmpty &&
           _usernameController.text.isNotEmpty &&
           _firstNameController.text.isNotEmpty &&
           _lastNameController.text.isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  Future<void> _register() async {
    final email = _emailController.text;
    final username = _usernameController.text;
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ตรวจสอบว่าแต่ละฟิลด์ถูกกรอกครบถ้วนหรือไม่
    if (!_areFieldsFilled()) {
      setState(() {
        _errorMessage = 'All fields are required.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }

    // ตรวจสอบว่าอีเมลมีรูปแบบถูกต้องหรือไม่
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Invalid email format.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }

    // ตรวจสอบความแข็งแกร่งของรหัสผ่าน
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>+-]').hasMatch(password)) {
      setState(() {
        _errorMessage = 'Password must include at least one special character.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }
    
    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters long.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password) || !RegExp(r'[a-z]').hasMatch(password)) {
      setState(() {
        _errorMessage = 'Password must include both upper and lower case letters.';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true; //เปลี่ยนสถานะเป็นกำลังโหลด
      _errorMessage = ''; //ล้างข้อความเเจ้งเตือนก่อนหน้า
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/users/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // ตรวจสอบสถานะการตอบกลับจากเซิร์ฟเวอร์
      if (response.statusCode == 200) {
        setState(() {
          _errorMessage = 'Registration successful. Redirecting to login...';
        });

        // รอ 2 วินาทีแล้วนำทางไปยังหน้า login
        await Future.delayed(Duration(seconds: 1));

        Navigator.pop(context);
      } 
        // เเจ้งเตือนสำหรับ username ที่ซ้ำกัน
        else if (response.statusCode == 409) {
        setState(() {
          _errorMessage = 'Username already exists. Please choose a different one.';
        });
        await Future.delayed(Duration(seconds: 2));
        setState(() {
          _errorMessage = '';
        });
      }
    } 
      //การเเจ้งเตือน เมือไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์
      catch (e) {
      setState(() {
        _errorMessage = 'Unable to connect to the internet. $e';
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _errorMessage = '';
      });
    } finally {
      setState(() {
        _isLoading = false; //เปลี่ยนสถานะเป็น ไม่โหลด
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFCC80), // สีพื้นหลัง
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 171, 45), // สีพื้นหลัง
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 35),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.email, color: Colors.orange),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.person, color: Colors.orange),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.person, color: Colors.orange),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.person, color: Colors.orange),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.vpn_key, color: Colors.orange),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _toggleConfirmPasswordVisibility,
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 35),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
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
                child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Register', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: _errorMessage.contains('Registration successful') ? Colors.green : Colors.red,
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
