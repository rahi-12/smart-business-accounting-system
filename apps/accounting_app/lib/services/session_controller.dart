import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../utils/friendly_error.dart';
import 'api_service.dart';

enum SessionStatus { loading, signedOut, ready, needsProfile, error }

class SessionController extends ChangeNotifier {
  SessionController._();

  static final instance = SessionController._();

  SessionStatus status = SessionStatus.loading;
  UserProfile? profile;
  String? errorMessage;
  StreamSubscription<User?>? _sub;
  bool _disposed = false;

  void start(ApiService api) {
    if (Firebase.apps.isEmpty) {
      profile = null;
      errorMessage = null;
      _set(SessionStatus.signedOut);
      return;
    }

    _sub ??= FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        profile = null;
        errorMessage = null;
        _set(SessionStatus.signedOut);
        return;
      }

      await refresh(api);
    });
  }

  Future<void> refresh(ApiService api) async {
    if (Firebase.apps.isEmpty) {
      profile = null;
      errorMessage = null;
      _set(SessionStatus.signedOut);
      return;
    }

    _set(SessionStatus.loading);
    try {
      profile = await api.getProfile();
      errorMessage = null;
      _set(SessionStatus.ready);
    } on ProfileNotFoundException {
      errorMessage = null;
      _set(SessionStatus.needsProfile);
    } on UnauthorizedException {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      errorMessage = friendlyError(e);
      _set(SessionStatus.error);
    }
  }

  void _set(SessionStatus s) {
    status = s;
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
