import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';

String friendlyError(Object error) {
  if (kDebugMode) {
    debugPrint('Raw exception: $error');
    debugPrintStack(stackTrace: StackTrace.current);
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No network connection.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  if (error is ApiException) {
    if (error.statusCode == 400 || error.statusCode == 409 || error.statusCode == 422) {
      return error.message;
    }
    return 'Cannot reach the server. Check that the backend is running.';
  }

  if (error is SocketException || error is http.ClientException) {
    return 'Cannot reach the server. Check that the backend is running.';
  }

  return error.toString();
}
