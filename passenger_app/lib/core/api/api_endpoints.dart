
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? "http://127.0.0.1:8000/api/v1";
  }

  static const String login = "/auth/login";
  static const String signup = "/auth/signup";
  static const String otpRequest = "/auth/otp/request"; // Added missing endpoint from logs
  static const String otpVerify = "/auth/otp/verify";
}
