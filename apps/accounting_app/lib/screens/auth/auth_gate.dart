import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/session_controller.dart';
import '../home/home_screen.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    SessionController.instance.start(_apiService);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, child) {
        final session = SessionController.instance;

        switch (session.status) {
          case SessionStatus.loading:
            return const Scaffold(
              backgroundColor: Color(0xFF07130E),
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E7A5B)),
                ),
              ),
            );
          case SessionStatus.signedOut:
            return const LoginScreen();
          case SessionStatus.ready:
            final profile = session.profile;
            if (profile == null) {
              return const LoginScreen();
            }
            return HomeScreen(profile: profile);
          case SessionStatus.needsProfile:
            return const CompleteProfileScreen();
          case SessionStatus.error:
            return Scaffold(
              backgroundColor: const Color(0xFF07130E),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.errorMessage ?? 'Something went wrong.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton(
                            onPressed: () => SessionController.instance.refresh(_apiService),
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
