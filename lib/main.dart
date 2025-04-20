import 'package:app/Home.dart';
import 'package:app/Login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
// ignore: unused_import
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DealsDray',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      theme: ThemeData(
        primaryColor: const Color(0xFFF45B69),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF45B69)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = false;
  String? _deviceId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      _collectAndSendDeviceInfo();
    });
  }

  // Helper method to show a temporary overlay message
  void _showOverlayMessage(String message) {
    if (!mounted) return;

    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _collectAndSendDeviceInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get device information - Currently device information is provided hardcoded because of privacy concerns.
      //The real data will be collected from user physical device such with few tweeks.
      Map<String, dynamic> deviceData = {};

      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceData['deviceType'] = 'android';
        deviceData['deviceId'] = androidInfo.id;
        deviceData['deviceName'] =
            '${androidInfo.manufacturer}-${androidInfo.model}';
        deviceData['deviceOSVersion'] = androidInfo.version.release;
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceData['deviceType'] = 'ios';
        deviceData['deviceId'] = iosInfo.identifierForVendor;
        deviceData['deviceName'] = iosInfo.name;
        deviceData['deviceOSVersion'] = iosInfo.systemVersion;
      }

      // IP address (simplified, in real scenarios we'd use a service)
      deviceData['deviceIPAddress'] =
          '11.433.445.66'; 

      // Get location information
      try {
        Position position = await _getCurrentLocation();
        deviceData['lat'] = position.latitude;
        deviceData['long'] = position.longitude;
      } catch (e) {
       
        deviceData['lat'] = 9.9312;
        deviceData['long'] = 76.2673;
      }

      // App information
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      Map<String, dynamic> appInfo = {'version': packageInfo.version};

      // Get install timestamp
      DateTime now = DateTime.now();
      String formattedTime = now.toIso8601String();
      appInfo['installTimeStamp'] = formattedTime;
      appInfo['uninstallTimeStamp'] = formattedTime;
      appInfo['downloadTimeStamp'] = formattedTime;

      // Buyer information (empty for now)
      deviceData['buyer_gcmid'] = "";
      deviceData['buyer_pemid'] = "";

      // Add app info to device data
      deviceData['app'] = appInfo;

      // Send device data to API
      await _sendDeviceData(deviceData);
    } catch (e) {
      _showOverlayMessage("Error collecting device info: ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendDeviceData(Map<String, dynamic> deviceData) async {
    try {
      final response = await http.post(
        Uri.parse('http://devapiv4.dealsdray.com/api/v2/user/device/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(deviceData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 1) {
        
          _deviceId = responseData['data']['deviceId'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('deviceId', _deviceId!);
          final userId = prefs.getString('userId') ?? 'null';

          // Navigate to next screen after successful API call
          Future.delayed(const Duration(seconds: 1), () {
            if(userId!='null'){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
            else if(mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }
          });
        } else {
          _showOverlayMessage(
            "Failed to register device: ${responseData['message']}",
          );
        }
      } else {
        _showOverlayMessage("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showOverlayMessage("Network error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 2,
              child: Image.asset('assets/background.png', fit: BoxFit.cover),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  
                    Image.asset('assets/logo.png', height: 150, width: 160),
                    const SizedBox(height: 8),

                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SpinKitDoubleBounce(
                          color: Theme.of(context).primaryColor,
                          size: 40.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
