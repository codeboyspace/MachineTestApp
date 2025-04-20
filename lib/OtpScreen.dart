import 'package:app/Home.dart';
import 'package:app/Register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OTPScreen extends StatefulWidget {
  final String mobileNumber;
  final String userId;
  final String deviceId;

  const OTPScreen({
    Key? key,
    required this.mobileNumber,
    required this.userId,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onOTPDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    if (_isAllDigitsFilled()) {
      _verifyOTP();
    }
  }

  bool _isAllDigitsFilled() {
    for (var controller in _controllers) {
      if (controller.text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  String _getCompleteOTP() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
  if (_isVerifying) return;

  setState(() {
    _isVerifying = true;
  });

  try {
    final response = await http.post(
      Uri.parse('http://devapiv4.dealsdray.com/api/v2/user/otp/verification'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'otp': _getCompleteOTP(),
        'deviceId': widget.deviceId,
        'userId': widget.userId,
      }),
    );

    setState(() {
      _isVerifying = false;
    });

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['status'] == 1) {
      final message = responseData['data']['message'] ?? 'OTP verified successfully';
      final registration_status = responseData['data']['registration_status'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (registration_status == 'Incomplete') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegisterPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['data']['message'] ?? 'Invalid OTP')),
      );
    }
  } catch (e) {
    setState(() {
      _isVerifying = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}


  Future<void> _resendOTP() async {
    if (_resendTimer > 0 || _isResending) return;
    
    setState(() {
      _isResending = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('http://devapiv4.dealsdray.com/api/v2/user/otp'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'mobileNumber': widget.mobileNumber,
          'deviceId': widget.deviceId,
        }),
      );

      setState(() {
        _isResending = false;
        _resendTimer = 60;
      });
      _startResendTimer();

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['status'] == 1) {
        // OTP resent successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent again')),
        );
        
        // Clear OTP fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        
      } else {
        // Error resending OTP
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['data']['message'] ?? 'Failed to resend OTP')),
        );
      }
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${remainingSeconds.toString().padLeft(2, '0')}';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/messageIcon.png',
                  fit: BoxFit.contain,
                ),
              ),

            ],
          ),

          const SizedBox(height: 40),
          const Text(
            'OTP Verification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.left,
          ),

          const SizedBox(height: 12),

          Text(
            'We have sent a unique OTP number\nto your mobile +91-${widget.mobileNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),

          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  onChanged: (value) => _onOTPDigitChanged(index, value),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_resendTimer),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: _resendTimer == 0 && !_isResending ? _resendOTP : null,
                child: Text(
                  'SEND AGAIN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _resendTimer == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
  }
}