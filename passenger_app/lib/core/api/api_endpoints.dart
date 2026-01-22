
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Use 127.0.0.1 with ADB Reverse (tcp:8000 tcp:8000)
  // This works for both Emulator and Physical Device (if adb reverse is run)
  static const String baseUrl = "http://127.0.0.1:8000/api/v1";

  static const String login = "/auth/login";
  static const String signup = "/auth/signup";
  static const String otpRequest = "/auth/otp/request"; // Added missing endpoint from logs
  static const String otpVerify = "/auth/otp/verify";
}
