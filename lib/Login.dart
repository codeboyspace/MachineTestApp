import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'OtpScreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPhoneSelected = true;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    if (_isPhoneSelected) {
      setState(() {
        _isButtonEnabled = _phoneController.text.length == 10;
      });
    } else {
      setState(() {
        _isButtonEnabled =
            _emailController.text.contains('@') &&
            _emailController.text.contains('.');
      });
    }
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('deviceId') ?? '';

      // API call to send OTP
      final response = await http.post(
        Uri.parse('http://devapiv4.dealsdray.com/api/v2/user/otp'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'mobileNumber': _phoneController.text,
          'deviceId': deviceId,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 1) {
        
        final userId = responseData['data']['userId'];
        await prefs.setString('userId', userId);
       
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OTPScreen(
                  mobileNumber: _phoneController.text,
                  userId: userId,
                  deviceId: deviceId,
                ),
          ),
        );
      } else {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['data']['message'] ?? 'Failed to send OTP',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              Center(
                child: Image.asset(
                  'assets/logo.png', 
                  height: 80,
                  width: 120,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '',
                style: TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPhoneSelected = true;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                _isPhoneSelected
                                    ? Colors.red
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Phone',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  _isPhoneSelected
                                      ? Colors.white
                                      : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPhoneSelected = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                !_isPhoneSelected
                                    ? Colors.red
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  !_isPhoneSelected
                                      ? Colors.white
                                      : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Glad to see you!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isPhoneSelected
                      ? 'Please provide your phone number'
                      : 'Please provide your email address',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child:
                    _isPhoneSelected
                        ? Column(
                          key: const ValueKey('phone'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF777777),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              onChanged: (value) => _validateInput(),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFDDDDDD),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        )
                        : Column(
                          key: const ValueKey('email'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF777777),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) => _validateInput(),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFDDDDDD),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isButtonEnabled && !_isLoading ? _sendOTP : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'SEND CODE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
